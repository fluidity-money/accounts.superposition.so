#!/bin/sh -e

cargo test --features std,proptest

export SPN_PANIC_REVERT=yes

# make accounts-cli.out

# make -B accounts.superposition.so.wasm

arbos-forge test --stylus-debug -vvvvv --ffi $@
