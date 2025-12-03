#!/bin/sh

if [ -z "$SPN_SUPERPOSITION_URL" ]; then
	>&2 echo "SPN_SUPERPOSITION_URL unset"
	exit 2
fi

if [ -z "$SPN_SUPERPOSITION_KEY" ]; then
	>&2 echo "SPN_SUPERPOSITION_KEY unset"
	exit 2
fi

cargo stylus deploy \
	--wasm-file "accounts.superposition.so.wasm" \
	--private-key "$SPN_SUPERPOSITION_KEY" \
	--endpoint "$SPN_SUPERPOSITION_URL" \
	--no-verify \
	        | sed -nr 's/.*deployed code at address: +.*(0x.{40}).*$/\1/p'
