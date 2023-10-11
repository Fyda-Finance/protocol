// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, FloorLegType, BuyLegType,SellLegType,TimeUnit,DIP_SPIKE,DCA_UNIT,CURRENT_PRICE } from "../AppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Modifiers {
    /// @notice 100% = 100000 -> 2 decimals
    uint256 constant MAX_PERCENTAGE = 10000;

    modifier onlyOwner {
        AppStorage storage s = LibDiamond.diamondStorage();
        require(msg.sender == s.owner, "Modifiers: Must be contract owner");
        _;
    }

    modifier validFloorLegType(FloorLegType _legType) {
        require(
            _legType == FloorLegType.NO_TYPE ||
            _legType == FloorLegType.LIMIT_PRICE ||
            _legType == FloorLegType.DECREASE_BY,
            "Invalid FloorLegType"
        );
        _;
    }

    modifier validBuyLegType(BuyLegType _legType) {
        require(
            _legType == BuyLegType.NO_TYPE ||
            _legType == BuyLegType.LIMIT_PRICE ||
            _legType == BuyLegType.CURRENT_PRICE,
            "Invalid BuyLegType"
        );
        _;
    }

    modifier validSellLegType(SellLegType _legType) {
        require(
            _legType == SellLegType.NO_TYPE ||
            _legType == SellLegType.LIMIT_PRICE ||
            _legType == SellLegType.INCREASE_BY ||
            _legType == SellLegType.CURRENT_PRICE,
            "Invalid SellLegType"
        );
        _;
    }

    modifier validDipSpike(DIP_SPIKE _spikeType) {
        require(
            _spikeType == DIP_SPIKE.NO_SPIKE ||
            _spikeType == DIP_SPIKE.DECREASE_BY ||
            _spikeType == DIP_SPIKE.INCREASE_BY ||
            _spikeType == DIP_SPIKE.FIXED_INCREASE ||
            _spikeType == DIP_SPIKE.FIXED_DECREASE,
            "Invalid DIP_SPIKE"
        );
        _;
    }

    modifier validDCAUnit(DCA_UNIT _unit) {
        require(
            _unit == DCA_UNIT.NO_UNIT ||
            _unit == DCA_UNIT.PERCENTAGE ||
            _unit == DCA_UNIT.FIXED,
            "Invalid DCA_UNIT"
        );
        _;
    }

    modifier validCurrentPrice(CURRENT_PRICE _priceType) {
        require(
            _priceType == CURRENT_PRICE.NOT_SELECTED ||
            _priceType == CURRENT_PRICE.BUY_CURRENT ||
            _priceType == CURRENT_PRICE.SELL_CURRENT,
            "Invalid CURRENT_PRICE"
        );
        _;
    }

    modifier validTimeUnit(TimeUnit _unit) {
        require(
            _unit == TimeUnit.NO_UNIT ||
            _unit == TimeUnit.HOURS ||
            _unit == TimeUnit.DAYS,
            "Invalid TimeUnit"
        );
        _;
    }
}