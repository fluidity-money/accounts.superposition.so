
accounts.superposition.so.wasm: $(shell find Cargo.* src -type f)
	@rm -f accounts.superposition.so.wasm
	@cargo build --release --target wasm32-unknown-unknown
	@./wasm-post.sh \
		target/wasm32-unknown-unknown/release/accounts-superposition-so.wasm \
		accounts.superposition.so.wasm
	@./check-codesize.sh accounts.superposition.so.wasm
