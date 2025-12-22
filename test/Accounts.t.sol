// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm, Test} from "forge-std/Test.sol";

import {strings} from "./strings.sol";

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

contract TestAccounts is Test {
    using strings for TestAccounts;

    address accounts;
    TestErc20 erc20;
    TestTarget target;

    uint256 constant CURVE_MAX = 115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function setUp() public {
        address impl = IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        );
        // Set up the precompiles:
        vm.etch(0xC3E443bE2Cfa4F41a5F5E4978D012847d355b419, IArbFoundry(address(vm)).deployStylusCode(
            "test/superposition-precompiles/precompiles-ed25519.wasm"
        ).code);
        erc20 = new TestErc20();
        target = new TestTarget();
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

    function test_online() public {
        vm.createSelectFork("https://rpc.superposition.so");
        address impl = IArbFoundry(address(vm)).deployStylusCode(
            "accounts.superposition.so.wasm"
        );
        bytes32 slotImpl = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        vm.store(0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2, slotImpl, bytes32(uint256(uint160(impl))));
        (bool rc, bytes memory rd) = 0xC5F97faab254a86C57003CE98f86A138648af35C.call(hex"0100000000010000002f68805f3bd70b1bf7bf8e119d8d294064352b4314454baa8c9d2b7da723305d56b080dd97d3e930d47c3aac1489e176c822ad826c9755390bbfd9988a977e05010000006c030c5cc283f791b26816f325b9c632d964f8a101094969000000001bab4a0c2973294e0b0f39c26c49794487c52788c7c5cce05e00356cd3f06c649564cb25ba649244b82e3c45ab775b2914c44743e0e0b2b691acc6bb16971ab9c7010000006c030c5cc283f791b26816f325b9c632d964f8a100000000000000000000000000000000000000000000000000000000000f424000000000000000000000000000000000000000000000000000000000000000004f64fc07a0060a9324a3a52692839a75754b16a4840000000000014793695aafe24a5ac500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd27acedd7532766afe49c1bbfa725a8f842ef33019b4514559c00000000000000000000");
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
        x = new string[](7);
        x[0] = "./accounts-cli.out";
        x[1] = "sign-fresh-backwards";
        x[2] = "1";
        x[3] = vm.toString(wallet.addr);
        bytes memory onboardPre = abi.encodePacked(
            "\x19Ethereum Signed Message:\n64",
           truncatedPubKey
        );
        bytes32 onboardDigest = keccak256(onboardPre);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet, onboardDigest);
        x[4] = vm.toString(v);
        x[5] = vm.toString(uint256(r));
        x[6] = vm.toString(uint256(s));
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
