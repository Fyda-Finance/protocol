// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy, StrategyParameters, SellLegType, BuyLegType, FloorLegType, DCA_UNIT, DIP_SPIKE, TimeUnit, Status, CURRENT_PRICE } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidSlippage, InvalidInvestToken, InvalidStableToken, TokensMustDiffer, AtLeastOneOptionRequired, InvalidBuyValue, InvalidBuyType, InvalidFloorValue, InvalidFloorType, InvalidSellType, InvalidSellValue, InvalidStableAmount, BuyAndSellAtMisorder, BuySellAndZeroAmount, InvalidInvestAmount, FloorValueGreaterThanBuyValue, FloorValueGreaterThanSellValue, SellPercentageWithDCA, FloorPercentageWithDCA, BothBuyTwapAndBTD, BuyDCAWithoutBuy, BuyTwapTimeInvalid, BuyTwapTimeUnitNotSelected, BothSellTwapAndSTR, SellDCAWithoutSell, SellTwapTimeUnitNotSelected, SellTwapTimeInvalid, SellTwapOrStrWithoutSellDCAUnit, SellDCAUnitWithoutSellDCAValue, StrWithoutStrValueOrType, BTDWithoutBTDType, BTDTypeWithoutBTDValue, BuyDCAWithoutBuyDCAUnit, BuyDCAUnitWithoutBuyDCAValue, InvalidHighSellValue, SellDCAValueRangeIsNotValid, BuyDCAValueRangeIsNotValid, DCAValueShouldBeLessThanIntitialAmount, OrphandStrategy, BuyNeverExecute } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

contract StrategyFacet is Modifiers {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, StrategyParameters parameter);

    function createStrategy(StrategyParameters memory _parameter) external {
        if (_parameter._investToken == address(0)) {
            revert InvalidInvestToken();
        }

        if (_parameter._stableToken == address(0)) {
            revert InvalidStableToken();
        }

        if (_parameter._investToken == _parameter._stableToken) {
            revert TokensMustDiffer();
        }

        if (!(_parameter._floor || _parameter._sell || _parameter._buy)) {
            revert AtLeastOneOptionRequired();
        }

        if (_parameter._sellType == SellLegType.INCREASE_BY && (_parameter._str || _parameter._sellTwap)) {
            revert SellPercentageWithDCA();
        }

        if (_parameter._floorType == FloorLegType.DECREASE_BY && (_parameter._buyTwap || _parameter._btd)) {
            revert FloorPercentageWithDCA();
        }

        if (_parameter._buy && _parameter._buyTwap && _parameter._btd) {
            revert BothBuyTwapAndBTD();
        }

        if ((_parameter._buyTwap || _parameter._btd) && !_parameter._buy) {
            revert BuyDCAWithoutBuy();
        }

        if (_parameter._buyTwap && _parameter._buyTwapTime <= 0) {
            revert BuyTwapTimeInvalid();
        }
        if (_parameter._buyTwap && _parameter._buyTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert BuyTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._str) {
            revert BothSellTwapAndSTR();
        }

        if ((_parameter._sellTwap || _parameter._str) && !_parameter._sell) {
            revert SellDCAWithoutSell();
        }
        if (_parameter._sellTwap && _parameter._sellTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert SellTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._sellTwapTime <= 0) {
            revert SellTwapTimeInvalid();
        }

        if ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.NO_UNIT) {
            revert SellTwapOrStrWithoutSellDCAUnit();
        }

        if (_parameter._sellDCAUnit != DCA_UNIT.NO_UNIT && _parameter._sellDCAValue == 0) {
            revert SellDCAUnitWithoutSellDCAValue();
        }

        if (_parameter._str && (_parameter._strValue == 0 || _parameter._strType == DIP_SPIKE.NO_SPIKE)) {
            revert StrWithoutStrValueOrType();
        }

        if (_parameter._btd && _parameter._btdType == DIP_SPIKE.NO_SPIKE) {
            revert BTDWithoutBTDType();
        }

        if (_parameter._btdType != DIP_SPIKE.NO_SPIKE && _parameter._btdValue == 0) {
            revert BTDTypeWithoutBTDValue();
        }

        if ((_parameter._btd || _parameter._buyTwap) && _parameter._buyDCAUnit == DCA_UNIT.NO_UNIT) {
            revert BuyDCAWithoutBuyDCAUnit();
        }

        if (_parameter._buyDCAUnit != DCA_UNIT.NO_UNIT && _parameter._buyDCAValue == 0) {
            revert BuyDCAUnitWithoutBuyDCAValue();
        }

        (uint256 price, uint80 roundId) = LibPrice.getPrice(_parameter._investToken, _parameter._stableToken);

        if (_parameter.current_price == CURRENT_PRICE.BUY_CURRENT) {
            _parameter._buyValue = price;
            _parameter._buyType = BuyLegType.LIMIT_PRICE;
        } else if (_parameter.current_price == CURRENT_PRICE.SELL_CURRENT) {
            _parameter._sellValue = price;
            _parameter._sellType = SellLegType.LIMIT_PRICE;
        }

        uint256 buyAt = _parameter._buyValue;

        if (_parameter._buy) {
            if (buyAt == 0) {
                revert InvalidBuyValue();
            }
            if (_parameter._buyType == BuyLegType.NO_TYPE) {
                revert InvalidBuyType();
            }
        }

        uint256 floorAt = 0;
        uint256 sellAt = 0;

        if (_parameter._floor && _parameter._floorType == FloorLegType.LIMIT_PRICE) {
            floorAt = _parameter._floorValue;
        } else if (
            _parameter._floor && _parameter._floorType == FloorLegType.DECREASE_BY && _parameter._investAmount > 0
        ) {
            uint256 floorPercentage = 100 - _parameter._floorValue;
            floorAt = (price * floorPercentage) / 100;
        }

        if (_parameter._sell && _parameter._sellType == SellLegType.LIMIT_PRICE) {
            sellAt = _parameter._sellValue;
        } else if (
            _parameter._sell && _parameter._sellType == SellLegType.INCREASE_BY && _parameter._investAmount > 0
        ) {
            uint256 sellPercentage = 100 + _parameter._sellValue;
            sellAt = (price * sellPercentage) / 100;
        }

        // Check if floor is chosen
        if (_parameter._floor) {
            if (_parameter._floorValue == 0) {
                revert InvalidFloorValue();
            }
            if (_parameter._floorType == FloorLegType.NO_TYPE) {
                revert InvalidFloorType();
            }
        }

        if (_parameter._sell || _parameter._str || _parameter._sellTwap) {
            if (_parameter._sellType == SellLegType.NO_TYPE) {
                revert InvalidSellType();
            }
            if (_parameter._sellValue == 0) {
                revert InvalidSellValue();
            }
            if (_parameter._highSellValue != 0 && (_parameter._str || _parameter._sellTwap)) {
                if (sellAt > _parameter._highSellValue) {
                    revert InvalidHighSellValue();
                }
            }
        }

        // Check if both buy and sell are chosen
        if (_parameter._buy && _parameter._sell) {
            if (!(_parameter._stableAmount > 0 || _parameter._investAmount > 0)) {
                revert BuySellAndZeroAmount();
            }
            if (buyAt > sellAt && _parameter._sellType == SellLegType.LIMIT_PRICE) {
                revert BuyAndSellAtMisorder();
            }
        }
        // Check if only buy is chosen
        if (_parameter._buy && !_parameter._sell && !_parameter._floor) {
            if (!(_parameter._stableAmount > 0)) {
                revert InvalidStableAmount();
            }
        }

        if (_parameter._buy && !_parameter._sell && !_parameter._floor) {
            if (_parameter._investAmount > 0) {
                revert OrphandStrategy();
            }
        }
        if (!_parameter._buy && _parameter._sell && _parameter._floor) {
            if (_parameter._stableAmount > 0) {
                revert OrphandStrategy();
            }
        }

        // Check if only sell is chosen
        if (
            (_parameter._sell || _parameter._floor) &&
            _parameter._investAmount > 0 &&
            (_parameter._completeOnSell || _parameter._cancelOnFloor) &&
            _parameter._buy
        ) {
            revert BuyNeverExecute();
        }

        // Check if floor and sell are chosen
        if (
            _parameter._floor &&
            _parameter._sell &&
            _parameter._sellType == SellLegType.LIMIT_PRICE &&
            _parameter._floorType == FloorLegType.LIMIT_PRICE
        ) {
            if (floorAt >= sellAt) {
                revert FloorValueGreaterThanSellValue();
            }
        }

        // Check if floor and buy are chosen
        if (_parameter._floor && _parameter._buy && _parameter._floorType == FloorLegType.LIMIT_PRICE) {
            if (floorAt >= buyAt) {
                revert FloorValueGreaterThanBuyValue();
            }
        }

        if (_parameter._slippage > LibTrade.MAX_PERCENTAGE) {
            revert InvalidSlippage();
        }

        uint256 sellPercentageAmount = 0;

        if ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            if (_parameter._sellDCAValue < 0 || _parameter._sellDCAValue > 100) {
                revert SellDCAValueRangeIsNotValid();
            }
            sellPercentageAmount = (_parameter._sellDCAValue * _parameter._investAmount) / 100;
        }

        if (
            ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.FIXED) ||
            ((_parameter._buyTwap || _parameter._btd) && _parameter._buyDCAUnit == DCA_UNIT.FIXED)
        ) {
            if (
                (_parameter._sellDCAValue > _parameter._investAmount) &&
                (_parameter._buyDCAValue > _parameter._stableAmount)
            ) {
                revert DCAValueShouldBeLessThanIntitialAmount();
            }
        }

        uint256 buyPercentageAmount = 0;

        if ((_parameter._buyTwap || _parameter._btd) && _parameter._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
            if (_parameter._buyDCAValue < 0 || _parameter._buyDCAValue > 100) {
                revert BuyDCAValueRangeIsNotValid();
            }
            buyPercentageAmount = (_parameter._buyDCAValue * _parameter._stableAmount) / 100;
        }

        uint256 budget = 0;

        if (_parameter._investAmount > 0) {
            budget = _parameter._investAmount * price;
        }

        if (_parameter._stableAmount > 0) {
            budget += _parameter._stableAmount;
        }

        s.strategies[s.nextStrategyId] = Strategy({
            user: msg.sender,
            sellAt: sellAt,
            floorAt: floorAt,
            buyAt: buyAt,
            sellPercentageAmount: sellPercentageAmount,
            strLastTrackedPrice: 0,
            sellTwapExecutedAt: block.timestamp,
            btdLastTrackedPrice: 0,
            buyPercentageAmount: buyPercentageAmount,
            buyTwapExecutedAt: block.timestamp,
            timestamp: block.timestamp,
            roundId: roundId,
            parameters: _parameter,
            investPrice: price,
            profit: 0,
            budget: budget,
            totalBuyDCAInvestment: 0,
            totalSellDCAInvestment: 0,
            status: Status.ACTIVE
        });

        s.nextStrategyId++;

        emit StrategyCreated(_parameter._investToken, _parameter._stableToken, _parameter);
    }

    function nextStartegyId() external view returns (uint256) {
        return s.nextStrategyId;
    }

    function getStrategy(uint256 id) external view returns (Strategy memory) {
        return s.strategies[id];
    }

    function cancelStrategy(uint256 id) external view {
        Strategy memory strategy = s.strategies[id];
        strategy.status = Status.CANCELLED;
    }
}
