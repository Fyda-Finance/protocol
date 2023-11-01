// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC173} from "../interfaces/IERC173.sol";
import {Modifiers} from "../utils/Modifiers.sol";
import {AppStorage} from "../AppStorage.sol";

contract PriceOracleFacet is Modifiers {
    AppStorage internal s;

    function setAssetFeed(address _asset, address _feed) external onlyOwner {
        s.feeds[_asset] = _feed;
    }
}
