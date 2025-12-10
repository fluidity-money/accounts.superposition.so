// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm, Test} from "forge-std/Test.sol";

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
        (bool rc, bytes memory rd) = 0xb838e2C1C9e525dFE18D35cd906aEe141ce9CfC2.call(hex"00a2676924d4dec99c5bda57abcaa31e6aae6eb15ac2036660dfe3dc9e6fa09c276221a9c005f6e47eb398fd867784cacfdcfff4e71cda102a9da68f6d3657c7e4be9f0e3a0ba3d52a0516f1dd714f4a374eceeaa9c313ec8e1e08eb3e924d61b778fc58447b006079a5d0ef1086bb4a666dcfaa0928010000009487fc30e10df8f561fda14ca174d805a4b5b5334b3cc411eeef15620fcf4c3cf99b4155f2cfb09d9a08b35c68e685c9065391defb05d16b7aaecefac2faaf0500000000010000006c030c5cc283f791b26816f325b9c632d964f8a10000000000000000000000000000000000000000000000000000000000000064ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ab5ec0c59332a5c993468357c70e96b348aeb62840000000000014742497404a67992b6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000000000000000000000000000006221a9c005f6e47eb398fd867784cacfdcfff4e7019b07efacef00000000000000000000");
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
