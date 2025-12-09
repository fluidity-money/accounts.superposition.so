// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vm, Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

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
    address client;
    TestErc20 erc20;
    TestTarget target;

    uint256 constant CURVE_MAX = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function setUp() public {
        //vm.createSelectFork("https://rpc.superposition.so");
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

    function old_test_online() public {
        address mainnet = 0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2;
        vm.etch(mainnet, accounts.code);
        (bool rc, bytes memory rd) = mainnet.call(hex"008ba4c056a9ccd6e140b6aff29ca7c170d3a4c4cf9891cfd0390930a58542b1e06221a9c005f6e47eb398fd867784cacfdcfff4e71c9cd9e911f3e16d8db0bb0f40b245f6906913e7a3a061e560da49bf713f26b3c73a782e741d3752d78b7a8b1264d10974d1e41e4895dc9f41f71eeb10978b1c4201000000b1e860f5fedbe12b71fdf75879321dd55d2c931198ef194b860a45b0e455d0230dc333c0a4d7c7961d5a265b8d2b65bac9735fe61da983a30224c6f17d60300e010000006c030c5cc283f791b26816f325b9c632d964f8a135b43769000000001b9f4c67a829562131e84ddcd8c0b7a6b209b7bb66d600dd70926965dd511613757a65fe72aec5d1dde4f013f8a01c89a97148957f609edacacdd50da602b717a4010000006c030c5cc283f791b26816f325b9c632d964f8a10000000000000000000000000000000000000000000000000000000000000064ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ab5ec0c59332a5c993468357c70e96b348aeb628400000000000147a1038983ec52d223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000000000000000000000000000006221a9c005f6e47eb398fd867784cacfdcfff4e7019b0160ff9800000000000000000000");
        if (!rc) {
            assembly {
                rd := add(rd, 4)
                mstore(rd, sub(mload(rd), 4))
            }
            string memory errorMessage = abi.decode(rd, (string));
            revert(errorMessage);
        }
    }

    function test_fuzzUserFlow(uint256 key) public {
        vm.assume(key > 0 && key < CURVE_MAX);
        Vm.Wallet memory wallet = vm.createWallet(key);
        vm.startPrank(wallet.addr);
        string[] memory x = new string[](3);
        x[0] = "./accounts-cli.out";
        x[1] = "pub-key-for-priv";
        x[2] = "1";
        bytes memory pubKey = vm.parseBytes(vm.toString(vm.ffi(x)));
        x = new string[](7);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-fresh-backwards";
        x[2] = "1";
        x[3] = vm.toString(wallet.addr);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet, bytes32(pubKey));
        x[4] = vm.toString(v);
        x[5] = vm.toString(uint256(r));
        x[6] = vm.toString(uint256(s));
        bytes memory cd = vm.parseBytes(vm.toString(vm.ffi(x)));
        (bool rc, bytes memory rd) = accounts.call(cd);
        assert(rc);
        client = abi.decode(rd, (address));
        x = new string[](8);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-token-spend";
        x[2] = "1";
        x[3] = "0";
        x[4] = vm.toString(address(erc20));
        x[5] = "100";
        x[6] = vm.toString(address(target));
        // The invoke selector:
        x[7] = "0xcab7f521";
        cd = vm.parseBytes(vm.toString(vm.ffi(x)));
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
