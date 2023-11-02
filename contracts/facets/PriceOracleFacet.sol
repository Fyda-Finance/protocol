// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC173 } from "../interfaces/IERC173.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage } from "../AppStorage.sol";

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
}
