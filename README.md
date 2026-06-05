
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

`0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2` is the proxy of the main accounts factory.
`0x5c153dcb6cfbd0ffe0f565185a19a1961df0903b` is the implementation.

`0x4B4e7127A5Ae64D7c96997B2c23BdB09C4d47d3F` is the implementation of the 9lives Authority
address. `0x0e3CD9653D9d9610281551d8E3C98035215EA18e` is the proxy.

`0xB35Fcae9a35533f26D8BED1a49bb4a6bFE53e6f8` is the upgradeable factory contract that's
used by the RPC service. `0x7cedA534aE176F1556a4A05fed3847ed2EFF912d` is the admin, and
the public key for the rpc service is
`0xf513398eeedc30f944006f896f157c21f2f6edd050a56cb9d97eb654826a9548`.

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
