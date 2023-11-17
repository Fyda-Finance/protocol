// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../utils/Modifiers.sol";
import { LibTrade } from "../libraries/LibTrade.sol";
import { LibUtil } from "../libraries/LibUtil.sol";
import { AppStorage } from "../AppStorage.sol";

/**
 * @title LensFacet
 * @dev This contract provides functions for calculating exchange rates and validating impact in trades.
 */
contract LensFacet is Modifiers {
    /**
     * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
     * please look at AppStorage.sol for more detail
     */
    AppStorage internal s;

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
     * @notice Validate impact for a trade based on exchange rate, price, and maximum allowed impact.
     * @param exchangeRate The calculated exchange rate for the trade.
     * @param price The current market price.
     * @param maxImpact The maximum allowable impact percentage.
     * @param isBuy A flag indicating whether it's a buy (true) or sell (false) trade.
     * @return The validated impact for the trade.
     */
    function validateImpact(
        uint256 exchangeRate,
        uint256 price,
        uint256 maxImpact,
        bool isBuy
    ) external pure returns (uint256) {
        return LibTrade.validateImpact(exchangeRate, price, maxImpact, isBuy);
    }

    /**
     * @notice Get the current nonce for a given account.
     * @param account The address of the account.
     * @return nonce current nonce.
     */
    function getNonce(address account) external view returns (uint256 nonce) {
        return s.nonces[account];
    }

    /**
     * @notice Get the current chain ID.
     * @return chain ID.
     */
    function getChainId() external view returns (uint256) {
        return LibUtil.getChainID();
    }
}
