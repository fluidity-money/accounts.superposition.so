#!/bin/sh -u

impl=0xefae04bf79b17396bcae06d67783149ac5998a51

forge create \
	--rpc-url $SPN_SUPERPOSITION_URL \
	--private-key "$SPN_SUPERPOSITION_KEY" \
	--broadcast \
	sol/UpgradeableProxy.sol:UpgradeableProxy \
	--constructor-args \
	"$impl" \
	"$SPN_ADMIN_ADDR" \
	"$SPN_PUBLIC_KEY"
