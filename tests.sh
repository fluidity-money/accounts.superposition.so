#!/bin/sh -e

# cargo test --features std

export SPN_PANIC_REVERT=yes

make -B accounts.superposition.so.wasm

arbos-forge test --stylus-debug -vvv --ffi $@
