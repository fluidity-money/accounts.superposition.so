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
        accounts = IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        );
        erc20 = new TestErc20();
        target = new TestTarget();
        bytes32 slotImpl = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        // Pretend to be a proxy with the factory during this test.
        vm.store(accounts, slotImpl, bytes32(uint256(uint160(accounts))));
    }


    function test_online() public {
        vm.createSelectFork("https://rpc.superposition.so");
        address mainnet = 0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2;
        assertEq(mainnet.codehash, accounts.codehash);
        vm.prank(0xBDD97993f4A72559461D63FbAA7Aa4C4A47D4d0B);
        (bool rc, bytes memory rd) = mainnet.call(hex"008ba4c056a9ccd6e140b6aff29ca7c170d3a4c4cf9891cfd0390930a58542b1e0c5f336b6c332ce756100d466ca19c67291e90a831c48f8e66443f06154d4939253704c27544dd5ed517fb59f61512d9b01c85e46b34f597cc5dd5ef5d2634f8f16ca83069d941410c808d3ccfadb1e49d40969778300000000");
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
