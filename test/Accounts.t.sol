// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm, Test} from "forge-std/Test.sol";

import {strings} from "./strings.sol";

import {IAuthority} from "../sol/IAuthority.sol";

import {IArbFoundry} from "./IArbFoundry.sol";

import {TransparentUpgradeableProxy} from "./TestTransparentUpgradeableProxy.sol";

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

contract TestAuthority is IAuthority {
    function allowed(bytes32) external pure returns (bool) {
        return true;
    }
}

contract TestAccounts is Test {
    using strings for TestAccounts;

    address accounts;
    TestErc20 erc20;
    TestTarget target;

    TestAuthority authority;

    uint256 constant CURVE_MAX = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function setUp() public {
        address impl = IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        );
        // Set up the precompiles:
        vm.etch(0xC3E443bE2Cfa4F41a5F5E4978D012847d355b419, IArbFoundry(address(vm)).deployStylusCode(
            "superposition-precompiles/precompiles-ed25519.wasm"
        ).code);
        erc20 = new TestErc20();
        target = new TestTarget();
        authority = new TestAuthority();
        accounts = address(new TransparentUpgradeableProxy(impl, address(this), ""));
    }

    function revertMsg(bool rc, bytes memory rd) internal pure {
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
        bytes memory pubKey = vm.ffi(x);
        string memory truncatedPubKey =
            strings.toString(strings.beyond(strings.toSlice(vm.toString(pubKey)), strings.toSlice("0x")));
        x = new string[](8);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-fresh-backwards";
        x[2] = "1";
        x[3] = vm.toString(wallet.addr);
        string memory truncatedAuthority =
            vm.toLowercase(strings.toString(
                strings.beyond(
                    strings.toSlice(vm.toString(address(authority))),
                    strings.toSlice("0x")
                )
            ));
        bytes memory onboardPre = abi.encodePacked(
            "\x19Ethereum Signed Message:\n153",
            "New Superposition account: ",
           truncatedPubKey,
           ", authority contract: ",
           truncatedAuthority
        );
        bytes32 onboardDigest = keccak256(onboardPre);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet, onboardDigest);
        x[4] = vm.toString(v);
        x[5] = vm.toString(uint256(r));
        x[6] = vm.toString(uint256(s));
        x[7] = truncatedAuthority;
        bytes memory cd = vm.ffi(x);
        (bool rc, bytes memory rd) = accounts.call(cd);
        revertMsg(rc, rd);
        address client = abi.decode(rd, (address));
        assertNotEq(address(0), client);
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
        revertMsg(rc, rd);
        assert(target.wasCalled());
    }
}
