#!/bin/sh -eu

# We make a pass similar to the way the node operates (it does a
# wasm2wat->wat2wasm pass). We also do this for arbos-foundry.

f="$(mktemp)"

wasm-opt \
	--dce \
	--rse \
	--signature-pruning \
	--strip-debug \
	--enable-bulk-memory \
	--strip \
	-Oz \
	"$1" \
	-o "$f.wasm1"

wasm2wat -o $f.wat $f.wasm1

# We also strip the developer's path from the final result if they use
# panic-revert:

sed -i "s@$(pwd)@/n@g" $f.wat

wat2wasm -o accounts.superposition.so.wasm $f.wat
