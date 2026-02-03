#!/bin/sh

if [ -z "$SPN_SUPERPOSITION_URL" ]; then
	>&2 echo "SPN_SUPERPOSITION_URL unset"
	exit 2
fi

if [ -z "$SPN_SUPERPOSITION_KEY" ]; then
	>&2 echo "SPN_SUPERPOSITION_KEY unset"
	exit 2
fi

bobcat-deploy \
	"$SPN_SUPERPOSITION_URL" \
	"$SPN_SUPERPOSITION_KEY" \
	accounts.superposition.so.wasm
