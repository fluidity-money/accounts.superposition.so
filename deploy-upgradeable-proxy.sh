#!/bin/sh -u

impl=0x92e89251b619a5ba2efc0f76efc3051595b489b7

forge create \
	--rpc-url https://rpc.superposition.so \
	--private-key "$SPN_PRIVATE_KEY" \
	--broadcast \
	sol/UpgradeableProxy.sol:UpgradeableProxy \
	--constructor-args \
	"$impl" \
	"$SPN_ADMIN_ADDR" \
	"$SPN_PUBLIC_KEY"
