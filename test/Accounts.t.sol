// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
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

    function test_userFlow() public {
        string[] memory x = new string[](3);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-fresh";
        x[2] = "1";
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
