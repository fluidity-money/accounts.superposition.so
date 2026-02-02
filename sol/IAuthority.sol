// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAuthority {
    function allowed(bytes32 hash) external view returns (bool);
}
