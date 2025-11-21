
.PHONY: clean

.DELETE_ON_ERROR:

accounts.superposition.so.wasm: $(shell find Cargo.* contract libaccounts -type f)
	@cargo build --release --target wasm32-unknown-unknown
	@./wasm-post.sh \
		target/wasm32-unknown-unknown/release/contract.wasm \
		accounts.superposition.so.wasm
	@./check-codesize.sh accounts.superposition.so.wasm

clean:
	@rm -rf target accounts.superposition.so.wasm
