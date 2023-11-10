// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import { LibDiamond } from "./LibDiamond.sol";
import { InvalidPrice, FeedNotFound } from "../utils/GenericErrors.sol";
import { AppStorage } from "../AppStorage.sol";

/**
 * @title LibPrice
 * @dev This library provides functions for fetching and manipulating asset prices.
 */
library LibPrice {
    address constant USD_QUOTE = 0x0000000000000000000000000000000000000348;

    /**
     * @notice Get the current price and round IDs of an asset relative to a unit.
     * @param asset The address of the asset.
     * @param unit The address of the unit (e.g., USD).
     * @return price The current price of the asset in terms of the unit.
     * @return investRoundId The round ID of the asset's price feed.
     * @return stableRoundId The round ID of the unit's price feed.
     */
    function getPrice(address asset, address unit) internal view returns (uint256 price, uint80, uint80) {
        AppStorage storage s = LibDiamond.diamondStorage();

        if (s.feeds[asset] == address(0) || s.feeds[unit] == address(0)) {
            revert FeedNotFound();
        }

        (uint80 investRoundId, int256 assetPrice, , , ) = AggregatorV2V3Interface(s.feeds[asset]).latestRoundData();
        (uint80 stableRoundId, int256 unitPrice, , , ) = AggregatorV2V3Interface(s.feeds[unit]).latestRoundData();

        if (assetPrice == 0 || unitPrice == 0) {
            revert InvalidPrice();
        }

        uint256 unitDecimals = IERC20Metadata(unit).decimals();
        price = (uint256(assetPrice) * (10 ** unitDecimals)) / uint256(unitPrice);

        return (price, investRoundId, stableRoundId);
    }

    /**
     * @notice Get the historical price of an asset relative to a unit at specific round IDs.
     * @param investRoundId The round ID of the asset's price feed.
     * @param stableRoundId The round ID of the unit's price feed.
     * @param asset The address of the asset.
     * @param unit The address of the unit (e.g., USD).
     * @return price The price of the asset in terms of the unit at the specified round IDs.
     */
    function getRoundData(
        uint80 investRoundId,
        uint80 stableRoundId,
        address asset,
        address unit
    ) internal view returns (uint256) {
        AppStorage storage s = LibDiamond.diamondStorage();

        if (s.feeds[asset] == address(0) || s.feeds[unit] == address(0)) {
            revert FeedNotFound();
        }

        (, int256 assetPrice, , , ) = AggregatorV2V3Interface(s.feeds[asset]).getRoundData(investRoundId);
        (, int256 unitPrice, , , ) = AggregatorV2V3Interface(s.feeds[unit]).getRoundData(stableRoundId);

        if (assetPrice == 0 || unitPrice == 0) {
            revert InvalidPrice();
        }

        uint256 unitDecimals = IERC20Metadata(unit).decimals();
        uint256 price = (uint256(assetPrice) * (10 ** unitDecimals)) / uint256(unitPrice);

        return price;
    }
}
