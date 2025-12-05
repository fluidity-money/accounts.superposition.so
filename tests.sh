#!/bin/sh -e

# cargo test --features std

make accounts.superposition.so.wasm

arbos-forge test --stylus-debug -vv --ffi $@
