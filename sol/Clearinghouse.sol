// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

struct ClearinghouseArg {
    Asset spnAsset;
    int24 tickSpacing;
    uint24 fee;
}

contract Clearinghouse {
    address immutable public CLEARINGHOUSE_SENDER = 0x6221a9c005f6e47eb398fd867784cacfdcfff4e7;

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

    function liquidate(ClearinghouseArg[] calldata _args) external {
        require(msg.sender == CLEARINGHOUSE_SENDER, "not sender");
        for (uint i = 0; i < _args.length; ++i) {

        }
    }
}
