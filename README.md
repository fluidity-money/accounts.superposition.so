
# Superposition Accounts

## Superposition Accounts

Superposition Accounts is a ed25519 smart account server that executes calldata on behalf
of the submitter, with a list of goals, permit onramping arguments, and more. The factory
looks up the address of the implementation before executing it. Proxies are configured
using a metamorphic proxy pattern spun up using the storage slot.

During registration, a user calls the factory contract, which validates the
signature and user data. The factory then uses create2 on the Ethereum address to call the
migration method, which simply delegatecalls back to the factory.

It's possible to register contract "authorities" for accounts registered. These servers
must support the function `allowed(address)(bool)`. These authorities are consulted
before executing a transaction to check if the hash of the contract they're calling is
whitelisted.

Migrations are possible by the EOA owner of the contract.

## Deployment layout

```dot
Factory -> Client [label="Looks up address"]
AccountServer -> Client [label="Executes the calldata with the goals on this server"]
```

## Onramping (account creation) story

```mermaid
flowchart LR
    Factory
    -->|Invokes account create using create2 and the sender address| Child
    -->|Delegatecalls its deployer address for the creation| Factory
```

## Lite Accounts

A LiteAccount contract is provided that forwards calldata given. The signer should be
cautious as to only sign blobs that are derived from the owner, the operator key, and the
chain id using the factory contract as the base with CREATE2.

## Dependencies

1. (https://github.com/OffchainLabs/cargo-stylus)[`cargo-stylus-sdk`] -- Cargo Stylus
binary for deployment.

2. (https://github.com/iosiro/arbos-foundry)[`arbos-foundry`] -- Needed for testing.

3. Rust with wasm32-unknown-unknown.

## Deployments

### Arbitrum

`0x34a464b4c77527736ea81b1a2bb200014691648c` is the implementation.
`0xeC9932f0862a7AFd26E258fDFE1201271ae3C3Aa` is the upgradeable proxy address.
`0x6221a9c005f6e47eb398fd867784cacfdcfff4e7` is the admin address (not an admin contract).
The factory address here is used by the other accounts for the fresh setup.

`0x92e89251b619a5ba2efc0f76efc3051595b489b7` is the enclave implementation, and
`0x58A5f520FF7A6F59863e8a73b066A975799d5d48` is the admin.
`0x27c74C72EdEAA9D17f482B2f1a961b293FdF345D` is the enclave proxy. The enclave public key
is `0xcb47705059ef7fb821fe4ee502682ba6fc94702a722a1f4cabebdc2351fed263` on Arbitrum.

## Building

	make

## Testing

Make sure to pull all git submodules:

	git submodule update --init --recursive

Then simply:

	./tests.sh

## Shoutouts

Special shoutout to arbos-foundry and Bernard Wagner for being proactive in resolving
feedback with arbos-foundry.
