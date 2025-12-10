
.PHONY: ed25519-priv-to-pub

ed25519-priv-to-pub: $(shell find Cargo.toml src)
	@cargo build --release
	@cp target/release/ed25519-priv-to-pub .

clean:
	@rm -rf target ed25519-priv-to-pub
