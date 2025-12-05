
.PHONY: build clean frontend

.DELETE_ON_ERROR:

comma := ,
CARGO_EXTRA_FEATURES := \
	$(if ${SPN_PANIC_REVERT},--features panic-revert)

build: accounts.superposition.so.wasm accounts-cli.out frontend bootstrap.zip

accounts.superposition.so.wasm: $(shell find Cargo.* contract libaccounts -type f)
	@rm -f accounts.superposition.so.wasm
	@cargo build --release --target wasm32-unknown-unknown --bin contract
	@./wasm-post.sh \
		target/wasm32-unknown-unknown/release/contract.wasm \
		accounts.superposition.so.wasm
	@./check-codesize.sh accounts.superposition.so.wasm

accounts-cli.out: $(shell find Cargo.* libaccounts accounts-cli -type f)
	@rm -f accounts-cli.out
	@cargo build --release --bin accounts-cli
	@mv target/release/accounts-cli accounts-cli.out

frontend: out/frontend_bg.wasm

out/frontend_bg.wasm: $(shell find Cargo.* libaccounts frontend -type f)
	@cd frontend && \
		cargo build --release --target wasm32-wasip1 && \
		wasm-bindgen target/wasm32-wasip1/release/frontend.wasm --out-dir ../out

accounts.superposition.so: $(shell find -name '*.go')
	@go build

bootstrap: accounts.superposition.so
	@cp accounts.superposition.so bootstrap

bootstrap.zip: bootstrap
	@zip bootstrap.zip bootstrap

clean:
	@rm -rf target accounts.superposition.so.wasm accounts-cli.out
