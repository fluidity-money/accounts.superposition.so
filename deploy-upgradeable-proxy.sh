#!/bin/sh -u

impl=0xcae96fc6a94f6cb986685b56367bfb3ff357f74c

forge create \
	--rpc-url https://rpc.superposition.so \
	--private-key "$SPN_PRIVATE_KEY" \
	--broadcast \
	sol/UpgradeableProxy.sol:UpgradeableProxy \
	--constructor-args \
	"$impl" \
	"$SPN_ADMIN_ADDR" \
	"$SPN_PUBLIC_KEY"
