# `superposition_libaccounts`

`superposition_libaccounts` contains the wire types and execution logic for Superposition's Ed25519 smart accounts.

It is shared by:

- the on-chain WASM contract, which decodes and executes requests;
- clients, which construct the same request types and Borsh-encode them as transaction calldata.

This is not an Ethereum ABI interface. Calls to an account use a Borsh-encoded [`Args`](src/lib.rs) value directly as the transaction data, without a four-byte function selector.

## What an account does

Each account is a deterministic proxy associated with an Ethereum EOA. Its state includes:

- one or more Ed25519 public keys, addressed by a numeric slot;
- the Ethereum owner used during creation and migration;
- consumed 16-byte nonces;
- the implementation version;
- an optional authority contract.

The usual flow is:

1. A client builds an operation such as `SolveArgs`.
2. The Ed25519 key in the selected slot signs the Borsh encoding of that operation using Ed25519ph/SHA-512.
3. Any relayer submits the signed, Borsh-encoded outer `Args` value to the account.
4. The account verifies the signature and consumes `ms_ts`, preventing the same operation from being replayed.
5. The account performs the requested token movements and/or contract call.

`ms_ts` is named after a millisecond timestamp, but on-chain it is simply a 16-byte, single-use value. It must be unique for that account. The existing clients conventionally use `u128::to_be_bytes()`.

## Main operations

### `Solve` and `SolveV2`

A solve is the general-purpose operation. One signed solve can:

1. submit zero or more EIP-2612 permits;
2. pull ERC-20 tokens into the account with `transferFrom`;
3. approve a target contract to spend those tokens;
4. call arbitrary calldata on the target;
5. check the account's remaining balance for every pulled token.

`Solve` uses the account's stored Ethereum owner for permits and transfers. `SolveV2` is the same operation with explicit `permit_owner` and `transfer_owner` addresses.

If an authority is configured, the target's code hash must be approved by calling `allowed(bytes32)` on the authority contract.

Several `SolveArgsSigArgs` values may be batched in one outer request. Each inner `SolveArgs` has its own signature and nonce.

### `TransferOnly`

Verifies one signature over a batch of ERC-20 transfers, optionally submits an EIP-2612 permit for each transfer, and then calls:

```text
 token.transferFrom(from, recipient, amount)
```

The batch must contain at least one transfer. This path does not call an arbitrary target contract and does not consult the authority contract.

### `Statement`

Verifies that the selected Ed25519 key signed a message and nonce. It performs no external call. A successful call consumes the nonce, so it can be used as an on-chain proof of a one-time signed statement.

### `FreshBackwards`

Creates a deterministic account for an Ethereum EOA, installs its first Ed25519 key, optionally installs an authority, and can immediately execute signed solve operations.

The EOA authorises creation with an Ethereum personal-sign signature over this exact text (lower-case, unprefixed hex values):

```text
New Superposition account: <64-hex-character-ed25519-key>, authority contract: <40-hex-character-authority-address>
```

A missing authority is represented by the zero address. The created proxy address is returned as a 32-byte word.

### `Version` and `Authority`

These are read-only requests which return the account's stored implementation version or authority address as a 32-byte word.

## Adding the crate

Inside this workspace:

```toml
[dependencies]
superposition_libaccounts = { path = "../superposition_libaccounts", features = ["std"] }
borsh = "1"
bobcat-sdk = { git = "https://github.com/fluidity-money/bobcat-sdk" }
ed25519-dalek = "2"
const-hex = "1"
```

The exact dependency sources and versions should normally match the workspace's root `Cargo.toml` and `Cargo.lock`.

The contract supports `no_std`. Client-side code should enable the crate's `std` feature.

## Common helpers

The examples below use these helpers:

```rust
use borsh::BorshSerialize;
use ed25519_dalek::{Digest, Sha512, SigningKey};
use superposition_libaccounts::{ArgsAddr, Sig};

fn address(value: &str) -> ArgsAddr {
    value.parse().expect("20-byte hex address")
}

// The contract verifies Ed25519ph signatures over the Borsh-encoded inner value.
fn sign_borsh<T: BorshSerialize>(key: &SigningKey, value: &T) -> Sig {
    let encoded = borsh::to_vec(value).expect("Borsh serialization");
    let mut digest = Sha512::new();
    digest.update(encoded);
    Sig(key.sign_prehashed(digest, None).expect("signing").to_bytes())
}

fn transaction_data(args: &superposition_libaccounts::Args) -> Vec<u8> {
    borsh::to_vec(args).expect("Borsh serialization")
}
```

Addresses may include an optional `0x` prefix. They must decode to exactly 20 bytes.

## Example: call a contract with tokens

This pulls 10 units of a token from the account's stored Ethereum owner, approves the target to spend those 10 units, then calls the target calldata.

```rust
use bobcat_sdk::maths::U;
use ed25519_dalek::SigningKey;
use superposition_libaccounts::{Args, FromArgs, SolveArgs, SolveArgsSigArgs};

let key = SigningKey::from_bytes(&[7u8; 32]);

let solve = SolveArgs {
    permit: vec![], // The owner has already approved the account.
    from: vec![FromArgs {
        token: address("0x1111111111111111111111111111111111111111"),
        to_take: U::from(10u64),
        // The implementation checks that the account's final balance is >= this value.
        max_unspent: U::ZERO,
    }],
    target: address("0x2222222222222222222222222222222222222222"),
    cd: const_hex::decode("12345678").unwrap(),
    ms_ts: 1_750_000_000_000u128.to_be_bytes(),
};

let request = Args::Solve {
    slot: 0,
    args: vec![SolveArgsSigArgs {
        sig: sign_borsh(&key, &solve),
        args: solve,
    }],
};

let data = transaction_data(&request);
// Send `data` as the transaction input to the smart-account address.
```

If the token supports EIP-2612, add a `Permit` to `solve.permit` instead of sending a separate approval transaction. Permit values can be parsed from JSON using `"{...}".parse::<Permit>()`; the signature fields are intentionally not directly mutable outside the crate.

## Example: transfer tokens directly

```rust
use bobcat_sdk::maths::U;
use ed25519_dalek::SigningKey;
use superposition_libaccounts::{Args, Transfer, TransferOnlyArgs};

let key = SigningKey::from_bytes(&[7u8; 32]);

let transfers = TransferOnlyArgs {
    args: vec![Transfer {
        from: address("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
        token: address("0x1111111111111111111111111111111111111111"),
        recipient: address("0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
        amt: U::from(25u64),
        permit: None, // `from` has already approved the account.
    }],
    ms_ts: 1_750_000_000_001u128.to_be_bytes(),
};

let sig = sign_borsh(&key, &transfers);
let data = transaction_data(&Args::TransferOnly {
    slot: 0,
    args: transfers,
    sig,
});
```

The signature covers the complete `TransferOnlyArgs` value, including every transfer and the nonce.

## Example: prove a signed statement

```rust
use ed25519_dalek::SigningKey;
use superposition_libaccounts::{Args, StatementArgs};

let key = SigningKey::from_bytes(&[7u8; 32]);
let statement = StatementArgs {
    msg: "I accept quote 42".to_owned(),
    ms_ts: 1_750_000_000_002u128.to_be_bytes(),
};

let sig = sign_borsh(&key, &statement);
let data = transaction_data(&Args::Statement {
    slot: 0,
    args: statement,
    sig,
});

// A successful eth_call or transaction means the signature was valid and the
// nonce had not already been used. Only a transaction persists nonce consumption.
```

## Example: query version or authority

```rust
use superposition_libaccounts::Args;

let version_call = transaction_data(&Args::Version);
let authority_call = transaction_data(&Args::Authority);

// Use each value as eth_call data against the account. The result is one
// 32-byte word. For Authority, the address occupies the low 20 bytes.
```

## Account creation outline

Creation needs both an Ethereum signature and an Ed25519 key, so it usually happens in a wallet-facing client:

```rust
use bobcat_sdk::maths::U;
use superposition_libaccounts::Args;

let request = Args::FreshBackwards {
    key: U(*ed25519_key.verifying_key().as_bytes()),
    eoa_addr: address("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
    v: ethereum_signature_v,
    r: ethereum_signature_r,
    s: ethereum_signature_s,
    solve_args: vec![],
    authority: None,
};

let data = transaction_data(&request);
// Send `data` to the accounts factory. Decode the returned 32-byte word as the
// newly created account address.
```

The Ethereum signature must recover to `eoa_addr` from the personal-sign message documented under `FreshBackwards`. If `solve_args` is non-empty, every inner solve must also carry a valid Ed25519ph signature.

## Encoding and signing rules

These details are easy to get wrong in clients:

- Encode outer requests and signed inner values with Borsh, not Ethereum ABI encoding.
- Sign only the inner `SolveArgs`, `TransferOnlyArgs`, or `StatementArgs`, not the outer `Args` enum.
- Sign using Ed25519ph with SHA-512, matching `SigningKey::sign_prehashed`.
- `U` values are fixed 32-byte unsigned integers. Follow the encoding used by `bobcat_sdk::maths::U` rather than substituting a variable-length integer.
- Keep `ms_ts` unique. A reused value reverts even when the signed content differs.
- The selected `slot` must contain the public key corresponding to the signing key.
- A valid signature does not need to come from the transaction sender; requests are designed to be relayed.
- Any failed permit, transfer, approval, authority check, target call, balance check, or nonce exchange reverts the entire operation.

## Source map

- [`src/lib.rs`](src/lib.rs): public request types and top-level dispatcher.
- [`src/entry_solve.rs`](src/entry_solve.rs): permit, token pull, target call, and post-call balance logic.
- [`src/entry_transfer_only.rs`](src/entry_transfer_only.rs): direct token-transfer batches.
- [`src/entry_statement.rs`](src/entry_statement.rs): signed statement verification.
- [`src/entry_fresh.rs`](src/entry_fresh.rs): EOA-authorised deterministic account creation.
- [`src/entry_migrate.rs`](src/entry_migrate.rs): account initialisation and implementation migration.
- [`src/storage.rs`](src/storage.rs): account storage layout.
- [`src/call_authority.rs`](src/call_authority.rs): optional target-code-hash allow-list check.
