// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers} from "../utils/Modifiers.sol";
import {LibTrade} from "../libraries/LibTrade.sol";

/**
 * @title LensFacet
 * @dev This contract provides functions for calculating exchange rates and validating slippage in trades.
 */
contract LensFacet is Modifiers {
    /**
     * @notice Calculate the exchange rate between two assets for a given trade.
     * @param fromAsset The address of the source asset.
     * @param fromAmount The amount of the source asset.
     * @param toAmount The amount of the target asset.
     * @return The calculated exchange rate.
     */
    function calculateExchangeRate(
        address fromAsset,
        uint256 fromAmount,
        uint256 toAmount
    ) external view returns (uint256) {
        return LibTrade.calculateExchangeRate(fromAsset, fromAmount, toAmount);
    }

    /**
     * @notice Validate slippage for a trade based on exchange rate, price, and maximum allowed slippage.
     * @param exchangeRate The calculated exchange rate for the trade.
     * @param price The current market price.
     * @param maxSlippage The maximum allowable slippage percentage.
     * @param isBuy A flag indicating whether it's a buy (true) or sell (false) trade.
     * @return The validated slippage for the trade.
     */
    function validateSlippage(
        uint256 exchangeRate,
        uint256 price,
        uint256 maxSlippage,
        bool isBuy
    ) external pure returns (uint256) {
        return
            LibTrade.validateSlippage(exchangeRate, price, maxSlippage, isBuy);
    }
}
