#!/bin/sh -u

impl=0x5c153dcb6cfbd0ffe0f565185a19a1961df0903b

forge create \
	--rpc-url https://rpc.superposition.so \
	--private-key "$SPN_PRIVATE_KEY" \
	--broadcast \
	sol/UpgradeableProxy.sol:UpgradeableProxy \
	--constructor-args \
	"$impl" \
	"$SPN_ADMIN_ADDR" \
	"$SPN_PUBLIC_KEY"
