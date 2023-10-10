// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { LibDiamond } from "./LibDiamond.sol";
import { InvalidPrice } from "../utils/GenericErrors.sol";
import { AppStorage } from "../AppStorage.sol";

library LibPrice {
    address constant USD_QUOTE = 0x0000000000000000000000000000000000000348;

    function getPrice(
        address asset,
        address unit
    ) internal view returns (uint256) {
        AppStorage storage s = LibDiamond.diamondStorage();

        FeedRegistryInterface registry = FeedRegistryInterface(s.chainlinkFeedRegistry);

        (,int assetPrice,,,) = registry.latestRoundData(asset, Denominations.USD);
        (,int unitPrice,,,) = registry.latestRoundData(unit, Denominations.USD);

        if (assetPrice == 0 || unitPrice == 0) {
            revert InvalidPrice();
        }

        uint unitDecimals = IERC20Metadata(unit).decimals();
        uint256 price = (uint256(assetPrice) * (10**unitDecimals)) / uint256(unitPrice);

        return price;
    }
}