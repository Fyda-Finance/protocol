// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { HighImpact } from "../utils/GenericErrors.sol";

/**
 * @title LibTrade
 * @dev This library provides functions for calculating exchange rates and validating slippage.
 */
library LibTrade {
    uint256 public constant MAX_PERCENTAGE = 10000;

    /**
    @dev Calculate exchange rate given input and output amounts
    @param fromAsset Address of the asset that was used to swap
    @param fromAmount Amount of the asset that was used to swap
    @param toAmount Amount of the asset that was received from swap
    @return uint256 Returns the exchange rate in toAsset unit
     */
    function calculateExchangeRate(
        address fromAsset,
        uint256 fromAmount,
        uint256 toAmount
    ) internal view returns (uint256) {
        IERC20Metadata _fromToken = IERC20Metadata(fromAsset);
        uint256 fromDecimals = _fromToken.decimals();
        return ((toAmount * (10 ** fromDecimals)) / fromAmount);
    }

    /**
     * @notice Validate the Impact of a swap.
     * @param exchangeRate The calculated exchange rate for the swap.
     * @param price The reference price for the swap.
     * @param maxImpact The maximum allowed Impact percentage.
     * @param isBuy A flag indicating if it's a buy operation (true) or not (false).
     * @return uint256 Returns the calculated Impact percentage.
     */
    function validateImpact(
        uint256 exchangeRate,
        uint256 price,
        uint256 maxImpact,
        bool isBuy
    ) internal pure returns (uint256) {
        uint256 impact = (price * MAX_PERCENTAGE) / exchangeRate;

        if (isBuy && impact < MAX_PERCENTAGE && MAX_PERCENTAGE - impact > maxImpact) revert HighImpact();
        if (!isBuy && impact > MAX_PERCENTAGE && impact - MAX_PERCENTAGE > maxImpact) revert HighImpact();
        uint256 impactValue;
        if (isBuy && impact < MAX_PERCENTAGE) {
            impactValue = MAX_PERCENTAGE - impact;
        } else if (!isBuy && impact > MAX_PERCENTAGE) {
            impactValue = impact - MAX_PERCENTAGE;
        }
        return impactValue;
    }
}
