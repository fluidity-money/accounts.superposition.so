#!/bin/sh -u

impl=0x66dab1fe11ec22e4700daaa50cdac03fcde9de2e

forge create \
	--rpc-url $SPN_SUPERPOSITION_URL \
	--private-key "$SPN_SUPERPOSITION_KEY" \
	--broadcast \
	sol/UpgradeableProxy.sol:UpgradeableProxy \
	--constructor-args \
	"$impl" \
	"$SPN_ADMIN_ADDR" \
	"$SPN_PUBLIC_KEY"
