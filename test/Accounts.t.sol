// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vm, Test} from "forge-std/Test.sol";

import {IArbFoundry} from "./IArbFoundry.sol";

contract TestErc20 {
    function transferFrom(address,address,uint256) external pure {}
    function transfer(address,uint256) external pure {}
    function balanceOf(address) external pure returns (uint256) {
        return 100;
    }
    function approve(address,uint256) external {}
}

contract TestTarget {
    bool public wasCalled;
    function invoke() external {
        wasCalled = true;
    }
}

contract TestAccounts is Test {
    address accounts;
    TestErc20 erc20;
    TestTarget target;

    uint256 constant CURVE_MAX = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function setUp() public {
        accounts = IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        );
        // Set up the precompiles:
        vm.etch(0xC3E443bE2Cfa4F41a5F5E4978D012847d355b419, IArbFoundry(address(vm)).deployStylusCode(
            "test/superposition-precompiles/precompiles-ed25519.wasm"
        ).code);
        erc20 = new TestErc20();
        target = new TestTarget();
        bytes32 slotImpl = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        // Pretend to be a proxy with the factory during this test.
        vm.store(accounts, slotImpl, bytes32(uint256(uint160(accounts))));
    }

    function test_online() public {
        vm.createSelectFork("https://rpc.superposition.so", 2385150);
        vm.etch(0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2, IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        ).code);
        (bool rc, bytes memory rd) = 0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2.call(hex"008ba4c056a9ccd6e140b6aff29ca7c170d3a4c4cf9891cfd0390930a58542b1e06221a9c005f6e47eb398fd867784cacfdcfff4e71c9cd9e911f3e16d8db0bb0f40b245f6906913e7a3a061e560da49bf713f26b3c73a782e741d3752d78b7a8b1264d10974d1e41e4895dc9f41f71eeb10978b1c4201000000c79ab40c57e6fb44fd3beb9acf339e685c60e3047bb48d72adf40811d2918047e273491833743a3d777ea3316f8dce2fb11b37ea470f4f4b796fc825efb4310b010000006c030c5cc283f791b26816f325b9c632d964f8a11c0c3869000000001c2619d3e4bbe2e5eabef34b03bd1e13ad71d931a848a32416be2c515fe1d5bc283afb8731be0e953d8fd514e1919c50e2d587a78cffacdc5b74bf081d0ed4fed2010000006c030c5cc283f791b26816f325b9c632d964f8a100000000000000000000000000000000000000000000000000000000000003e8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ab5ec0c59332a5c993468357c70e96b348aeb628400000000000147a1038983ec52d22300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000006221a9c005f6e47eb398fd867784cacfdcfff4e7019b02b85f8b00000000000000000000");
        if (!rc) {
            assembly {
                rd := add(rd, 4)
                mstore(rd, sub(mload(rd), 4))
            }
            string memory errorMessage = abi.decode(rd, (string));
            revert(errorMessage);
        }
    }

    function test_fuzzUserFlow() public {
        uint256 key = 10;
        vm.assume(key > 0 && key < CURVE_MAX);
        Vm.Wallet memory wallet = vm.createWallet(key);
        vm.startPrank(wallet.addr);
        string[] memory x = new string[](3);
        x[0] = "./accounts-cli.out";
        x[1] = "pub-key-for-priv";
        x[2] = "1";
        bytes memory pubKey = vm.ffi(x);
        x = new string[](7);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-fresh-backwards";
        x[2] = "1";
        x[3] = vm.toString(wallet.addr);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet, bytes32(pubKey));
        x[4] = vm.toString(v);
        x[5] = vm.toString(uint256(r));
        x[6] = vm.toString(uint256(s));
        bytes memory cd = vm.ffi(x);
        //contract	digest: b4c0c77aa00a1c6ee4f102c634708d06962e8ca85e1f7f2fad381bd47ecbce5615547d9c0d54a86f5f6e57852b219b554180853a424b2bdd36a12e044746bdc0, ed owner: 34696762660094522240561638380233039462005209205579307443945330103699145865769, sig: 94a229267c92eef0edb5ddbbb434b3d0b7f5496dc0c179bc9da729853cc8f04a9ffa0ce44f3c042659856fa23f856fadd59ded62aae465c7660f6ba1f7e2c609] test_fuzzUserFlow() (gas: 341814)
        //client	digest: b4c0c77aa00a1c6ee4f102c634708d06962e8ca85e1f7f2fad381bd47ecbce5615547d9c0d54a86f5f6e57852b219b554180853a424b2bdd36a12e044746bdc0, ed owner: 4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29, sig: 94a229267c92eef0edb5ddbbb434b3d0b7f5496dc0c179bc9da729853cc8f04a9ffa0ce44f3c042659856fa23f856fadd59ded62aae465c7660f6ba1f7e2c609
        (bool rc, bytes memory rd) = accounts.call(cd);
        if (!rc) {
            assembly {
                rd := add(rd, 4)
                mstore(rd, sub(mload(rd), 4))
            }
            string memory errorMessage = abi.decode(rd, (string));
            revert(errorMessage);
        }
        address client = abi.decode(rd, (address));
        x = new string[](9);
        // We've observed some strange hex behaviour with Foundry, so we're
        // setting the ms_ts to 0 explicitly:
        x[0] = "./accounts-cli.out";
        x[1] = "sign-token-spend";
        x[2] = "1"; // Private key
        x[3] = "0"; // Slot
        x[4] = vm.toString(address(erc20));
        x[5] = "100";
        x[6] = vm.toString(address(target));
        // The ms ts:
        x[7] = "0";
        // The invoke selector:
        x[8] = "0xcab7f521";
        cd = vm.ffi(x);
        (rc, rd) = client.call(cd);
        if (!rc) {
            assembly {
                rd := add(rd, 4)
                mstore(rd, sub(mload(rd), 4))
            }
            string memory errorMessage = abi.decode(rd, (string));
            revert(errorMessage);
        }
        assert(target.wasCalled());
    }
}
