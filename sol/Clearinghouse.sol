// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

contract Clearinghouse {
    IV4Quoter immutable public QUOTER = IV4Quoter(address(0));

    function estimateEthValue(
        address _asset,
        uint24 _fee,
        int24 _tickSpacing,
        uint128 _amt
    ) external returns (uint256 amountOut) {
        (amountOut,) =
            QUOTER.quoteExactInputSingle(IV4Quoter.QuoteExactSingleParams({
                poolKey: PoolKey({
                    currency0: Currency.wrap(address(0)),
                    currency1: Currency.wrap(_asset),
                    fee: _fee,
                    tickSpacing: _tickSpacing,
                    hooks: IHooks(address(0))
                }),
                zeroForOne: false,
                exactAmount: _amt,
                hookData: ""
            })
        );
    }
}
