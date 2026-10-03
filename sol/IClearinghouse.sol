// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

enum Asset {
    USDC,
    ARB,
    WETH,
    WBTC,
    USDG,
    SPY
}

interface IClearinghouse {
    function estimateEthValueCheckAccountsUniswap(
        Asset asset,
        uint24 fee,
        int24 tickSpacing,
        uint128 amount
    ) external view returns (uint256 amount);
}
