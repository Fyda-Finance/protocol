// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC173 } from "../interfaces/IERC173.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage } from "../AppStorage.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/**
 * @title PriceOracleFacet
 * @dev This contract manages asset price feeds used by the diamond contract.
 */
contract PriceOracleFacet is Modifiers {
    AppStorage internal s;

    /**
     * @notice Sets the asset price feed address for a specific asset.
     * @param _asset The address of the asset.
     * @param _feed The address of the price feed for the asset.
     */
    function setAssetFeed(address _asset, address _feed) external onlyOwner {
        s.feeds[_asset] = _feed;
    }

    /**
     * @notice Sets the asset price feed addresses for a list of assets.
     * @param _assets The addresses of the assets.
     * @param _feeds The addresses of the price feeds for the assets.
     */
    function setAssetFeeds(address[] calldata _assets, address[] calldata _feeds) external onlyOwner {
        require(_assets.length == _feeds.length, "length mismatch");
        for (uint256 i = 0; i < _assets.length; i++) {
            s.feeds[_assets[i]] = _feeds[i];
        }
    }

    /**
     * @notice Get the current price and round IDs of an asset relative to a unit.
     * @param asset The address of the asset.
     * @param unit The address of the unit (e.g., USD).
     * @return price The current price of the asset in terms of the unit.
     * @return investRoundId The round ID of the asset's price feed.
     * @return stableRoundId The round ID of the unit's price feed.
     */
    function getPrice(address asset, address unit) external view returns (uint256 price, uint80, uint80) {
        return LibPrice.getPrice(asset, unit);
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
    ) external view returns (uint256) {
        return LibPrice.getRoundData(investRoundId, stableRoundId, asset, unit);
    }

    /**
     * @notice Get the price of an asset in USD.
     * @param asset The address of the asset.
     * @return price The price of the asset in USD
     */
    function getUSDPrice(address asset) external view returns (uint80, int256) {
        (uint80 roundId, int256 assetPrice, , , ) = AggregatorV2V3Interface(s.feeds[asset]).latestRoundData();
        return (roundId, assetPrice);
    }

    /**
     * @notice Get the price of an asset in USD.
     * @param asset The address of the asset.
     * @param roundId the round for which price is required.
     * @return price The price of the asset based on round Id
     */
    function getPriceBasedOnRoundId(address asset, uint80 roundId) external view returns (uint256) {
        return LibPrice.getPriceBasedOnRoundId(asset, roundId);
    }
}
