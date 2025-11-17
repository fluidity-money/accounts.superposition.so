// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

import {IArbFoundry} from "./IArbFoundry.sol";

import {IAccounts.superposition.so} from "../src/IAccounts.superposition.so.sol";

contract Accounts.superposition.so is Test {
    IAccounts.superposition.so c;

    function setUp() external {
        c = IAccounts.superposition.so(IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        ));
    }

    function test_contractDeployed() public view {
        assertEq(123, c.hello());
    }
}
