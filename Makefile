
include config.mk

.PHONY: build clean frontend

.DELETE_ON_ERROR:

comma := ,
CARGO_EXTRA_FEATURES := \
	$(if ${SPN_PANIC_REVERT},--features panic-revert)

build: \
	arbitrum.accounts.superposition.so.wasm \
	robinhood-mainnet.accounts.superposition.so.wasm \
	robinhood-testnet.accounts.superposition.so.wasm \
	arbitrum.clearinghouse.superposition.so.wasm \
	robinhood-mainnet.clearinghouse.superposition.so.wasm \
	accounts-cli.out \
	bootstrap.zip

RUST_CODE := $(shell find Cargo.* superposition_libaccounts -type f)

RUST_CODE_CONTRACT := ${RUST_CODE} $(shell find contract -type f)

RUST_CODE_CLEARINGHOUSE := ${RUST_CODE} $(shell find contract-clearinghouse -type f)

BUILD_WASM := cargo build --release --target wasm32-unknown-unknown

BUILD_CONTRACT := ${BUILD_WASM} --bin contract

BUILD_CLEARINGHOUSE := ${BUILD_WASM} --bin contract-clearinghouse

WASM_POST := ./wasm-post.sh

arbitrum.accounts.superposition.so.wasm: ${RUST_CODE_CONTRACT}
	@${BUILD_CONTRACT} --features network-arbitrum
	@${WASM_POST} \
		contract.wasm \
		arbitrum.accounts.superposition.so.wasm

robinhood-mainnet.accounts.superposition.so.wasm: ${RUST_CODE_CONTRACT}
	@${BUILD_CONTRACT} --features network-robinhood-mainnet
	@${WASM_POST} \
		contract.wasm \
		robinhood-mainnet.accounts.superposition.so.wasm

robinhood-testnet.accounts.superposition.so.wasm: ${RUST_CODE_CONTRACT}
	@${BUILD_CONTRACT} --features network-robinhood-testnet
	@${WASM_POST} \
		contract.wasm \
		robinhood-testnet.accounts.superposition.so.wasm

arbitrum.clearinghouse.superposition.so.wasm: ${RUST_CODE_CLEARINGHOUSE}
	@${BUILD_CLEARINGHOUSE} --features network-arbitrum
	@${WASM_POST} \
		contract-clearinghouse.wasm \
		arbitrum.clearinghouse.superposition.so.wasm

robinhood-mainnet.clearinghouse.superposition.so.wasm: ${RUST_CODE_CLEARINGHOUSE}
	@${BUILD_CLEARINGHOUSE} --features network-robinhood
	@${WASM_POST} \
		contract-clearinghouse.wasm \
		robinhood-mainnet.clearinghouse.superposition.so.wasm

accounts-cli.out: $(shell find Cargo.* superposition_libaccounts accounts-cli -type f)
	@rm -f accounts-cli.out
	@cargo build --release --bin accounts-cli
	@mv target/release/accounts-cli accounts-cli.out

ed25519-dalek-ph.out: $(shell find Cargo.* ed25519-dalek-ph -type f)
	@rm -f ed25519-dalek-ph.out
	@cd ed25519-dalek-ph && \
		cargo build --release --bin ed25519-dalek-ph && \
		mv target/release/ed25519-dalek-ph ../ed25519-dalek-ph.out

accounts.superposition.so: $(shell find -name '*.go') ed25519-dalek-ph.out
	@go build

bootstrap: accounts.superposition.so
	@cp accounts.superposition.so bootstrap

bootstrap.zip: bootstrap ed25519-dalek-ph.out
	@zip bootstrap.zip bootstrap ed25519-dalek-ph.out

clean:
	@cargo clean
	@rm -r \
		accounts.superposition.so.wasm \
		accounts-cli.out \
		accounts-superposition.so \
		bootstrap \
		bootstrap.zip \
		ed25519-dalek-ph.out
