#!/bin/sh -e

if ! which convertor-fuzz >/dev/null 2>&1; then
	>&2 echo convertor-fuzz not in path
	exit 1
fi

cargo test --features std,proptest

export SPN_PANIC_REVERT=yes

export FOUNDRY_FUZZ_RUNS=1

make accounts-cli.out

make -B accounts.superposition.so.wasm

# arbos-forge test --stylus-debug -vvvvv --ffi $@

arbos-forge test --stylus-debug --ffi -vv $@
