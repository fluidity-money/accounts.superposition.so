
.PHONY: build clean frontend

.DELETE_ON_ERROR:

comma := ,
CARGO_EXTRA_FEATURES := \
	$(if ${SPN_PANIC_REVERT},--features panic-revert)

build: accounts.superposition.so.wasm accounts-cli.out frontend bootstrap.zip

accounts.superposition.so.wasm: $(shell find Cargo.* contract superposition_libaccounts -type f)
	@rm -f accounts.superposition.so.wasm
	@cargo build --release --target wasm32-unknown-unknown --bin contract
	@./wasm-post.sh \
		target/wasm32-unknown-unknown/release/contract.wasm \
		accounts.superposition.so.wasm
	@./check-codesize.sh accounts.superposition.so.wasm

accounts-cli.out: $(shell find Cargo.* superposition_libaccounts accounts-cli -type f)
	@rm -f accounts-cli.out
	@cargo build --release --bin accounts-cli
	@mv target/release/accounts-cli accounts-cli.out

ed25519-dalek-ph.out: $(shell find Cargo.* ed25519-dalek-ph -type f)
	@rm -f ed25519-dalek-ph.out
	@cd ed25519-dalek-ph && \
		cargo build --release --bin ed25519-dalek-ph && \
		mv target/release/ed25519-dalek-ph ../ed25519-dalek-ph.out

frontend: out/frontend_bg.wasm

out/frontend_bg.wasm: $(shell find Cargo.* superposition_libaccounts frontend -type f)
	@cd frontend && \
		cargo build --release --target wasm32-wasip1 && \
		wasm-bindgen target/wasm32-wasip1/release/frontend.wasm --out-dir ../out

accounts.superposition.so: $(shell find -name '*.go') ed25519-dalek-ph.out
	@go build

bootstrap: accounts.superposition.so
	@cp accounts.superposition.so bootstrap

bootstrap.zip: bootstrap ed25519-dalek-ph.out
	@zip bootstrap.zip bootstrap ed25519-dalek-ph.out

clean:
	@rm -rf \
		target \
		accounts.superposition.so.wasm \
		accounts-cli.out \
		accounts-superposition.so \
		bootstrap \
		bootstrap.zip \
		ed25519-dalek-ph.out
