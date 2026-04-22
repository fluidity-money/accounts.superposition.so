// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract LiteFactory {
    address public impl;

    event Created(
        address indexed owner,
        bytes32 indexed operator,
        address indexed result
    );

    function create(address _owner, bytes32 _operator) external returns (address d) {
         // All code here comes from LiteAccount.huff:
        bytes memory c = abi.encodePacked(
            hex"60015f5560ec80600d3d393df373",
            _owner,
            hex"331461002f575f54610037575b63fe835e355b5f526004601cfd5b5f355f555f5ff35b60406060606480360383360384602037600160015f526011601f2080546100215755305f525f5f602c3603600c732f6bc5ac6b08bf93bc6fc9be156449b676bf8bb25afa3d5f5f3e7f",
            _operator,
            hex"8552845f85375f5f60a05f73c3e443be2cfa4f41a5f5e4978d012847d355b4195afa63cba605a381156100275783855f375f5f855f5f6050358b1c5af13d5f5f3e3d5f826100ea57fd5bf3"
        );
	// This is safe to use this way, since the operator and owner
	// address is in the bytecode. So the user only needs to be
	// sensitive to the chain id as a precaution:
        assembly {
            d := create2(0, add(c, 0x20), mload(c), chainid())
        }
        emit Created(_owner, _operator, d);
    }
}
