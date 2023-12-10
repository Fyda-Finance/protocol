// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import { LibDiamond } from "./LibDiamond.sol";
import { InvalidPrice, FeedNotFound } from "../utils/GenericErrors.sol";
import { AppStorage } from "../AppStorage.sol";

error SequencerDown();
error GracePeriodNotOver();
error PriceExpired();

/**
 * @title LibPrice
 * @dev This library provides functions for fetching and manipulating asset prices.
 */
library LibPrice {
    address constant USD_QUOTE = 0x0000000000000000000000000000000000000348;
    uint256 private constant GRACE_PERIOD_TIME = 3600;

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

        AggregatorV2V3Interface sequencerUptimeFeed = AggregatorV2V3Interface(s.sequencerUptimeFeed);

        if (address(sequencerUptimeFeed) != address(0)) {
            (
                ,
                /*uint80 roundID*/ int256 answer,
                uint256 startedAt /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
                ,

            ) = sequencerUptimeFeed.latestRoundData();

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = answer == 0;
            if (!isSequencerUp) {
                revert SequencerDown();
            }

            // Make sure the grace period has passed after the
            // sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;
            if (timeSinceUp <= GRACE_PERIOD_TIME) {
                revert GracePeriodNotOver();
            }
        }

        if (s.feeds[asset] == address(0) || s.feeds[unit] == address(0)) {
            revert FeedNotFound();
        }

        (uint80 investRoundId, int256 assetPrice, , uint256 investUpdatedAt, ) = AggregatorV2V3Interface(s.feeds[asset])
            .latestRoundData();
        (uint80 stableRoundId, int256 unitPrice, , uint256 stableUpdatedAt, ) = AggregatorV2V3Interface(s.feeds[unit])
            .latestRoundData();

        if (assetPrice == 0 || unitPrice == 0) {
            revert InvalidPrice();
        }

        if (
            block.timestamp - investUpdatedAt > s.maxStalePeriod || block.timestamp - stableUpdatedAt > s.maxStalePeriod
        ) {
            revert PriceExpired();
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

    /**
     * @notice Get the price of an asset in USD.
     * @param asset The address of the asset.
     * @return price The price of the asset in USD
     */
    function getUSDPrice(address asset) internal view returns (uint256) {
        AppStorage storage s = LibDiamond.diamondStorage();

        if (s.feeds[asset] == address(0)) {
            revert FeedNotFound();
        }
        (, int256 assetPrice, , , ) = AggregatorV2V3Interface(s.feeds[asset]).latestRoundData();
        if (assetPrice == 0) {
            revert InvalidPrice();
        }
        return uint256(assetPrice);
    }

    /**
     * @notice Get the price of an asset in USD.
     * @param asset The address of the asset.
     * @param roundId the round for which price is required.
     * @return price The price of the asset based on round Id
     */
    function getPriceBasedOnRoundId(address asset, uint80 roundId) internal view returns (uint256) {
        AppStorage storage s = LibDiamond.diamondStorage();

        if (s.feeds[asset] == address(0)) {
            revert FeedNotFound();
        }
        (, int256 assetPrice, , , ) = AggregatorV2V3Interface(s.feeds[asset]).getRoundData(roundId);
        if (assetPrice == 0) {
            revert InvalidPrice();
        }
        return uint256(assetPrice);
    }
}
