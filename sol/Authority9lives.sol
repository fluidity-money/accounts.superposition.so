// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAuthority} from "./IAuthority.sol";

interface I9livesFactory {
    function dppmTradingHash() external view returns (bytes32);
    function ammTradingHash() external view returns (bytes32);
}

contract Authority9lives is IAuthority {
    event Registered(bytes32 indexed hash, bool indexed allowed);

    uint256 private version;

    address public operator;

    I9livesFactory public factory;

    mapping(bytes32 => bool) public allowed;

    function init(address _owner, I9livesFactory _factory) external {
        require(version == 0, "already initialised");
        operator = _owner;
        factory = _factory;
        version = 1;
    }

    function register(bytes32 _hash, bool _allowed) public {
       require(msg.sender == operator, "not operator");
       emit Registered(_hash, _allowed);
       allowed[_hash] = _allowed;
    }

    function scan() external {
        // The two register functions here should check the sender:
        register(factory.dppmTradingHash(), true);
        register(factory.ammTradingHash(), true);
    }
}
