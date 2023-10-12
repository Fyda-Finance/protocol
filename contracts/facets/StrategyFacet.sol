// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy,StrategyParameters, SellLegType, FloorLegType, DCA_UNIT,DIP_SPIKE } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidSlippage } from "../utils/GenericErrors.sol";

contract StrategyFacet is Modifiers {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, uint256 buyAt, uint256 amount);

    function createStrategy(StrategyParameters memory _parameter) external {
        if (_parameter._slippage > MAX_PERCENTAGE) {
            revert InvalidSlippage();
        }

        require(_parameter._investToken != address(0), "InvestToken cannot be null");
        require(_parameter._stableToken != address(0), "StableToken cannot be null");
        require(_parameter._investToken != _parameter._stableToken, "InvestToken and StableToken must be different");
        require(_parameter._floor || _parameter._sell || _parameter._buy, "At least one of floor, sell, or buy must be true");

        if (_parameter._buy) {
        require(_parameter._buyAt > 0, "BuyAt must be greater than zero");
        }

       // Check if floor is chosen
       if (_parameter._floor) {
        require(_parameter._floorAt > 0, "FloorValue must be greater than zero");
       }

    // Check if sell is chosen
        if ((_parameter._sell || _parameter._str || _parameter._sellTwap) &&_parameter._sellAt == 0) {
           revert("sellValue must be provided if DCA or non-DCA sell is chosen.");
        }
        // Check if both buy and sell are chosen
        if (_parameter._buy && _parameter._sell) {
        require(_parameter._stableAmount > 0 || _parameter._investAmount > 0, "You should provide stableAmount or investAmount because you have chosen both buy and sell");
        require(_parameter._buyAt < _parameter._sellAt, "BuyAt must be less than SellAt");
    }
// Check if only buy is chosen
    if (_parameter._buy && !_parameter._sell &&  !_parameter._floor) {
        require(_parameter._stableAmount > 0, "StableAmount must be greater than zero when only buy is chosen");
  
    }

    if (
    _parameter._buy &&
    !_parameter._sell &&
    !_parameter._floor &&
    _parameter._investAmount > 0
) {
    revert("You should not provide invest amount when only buy");
}

    // Check if only sell is chosen
    if ((_parameter._sell||_parameter._floor) && !_parameter._buy) {
        require(_parameter._investAmount > 0, "InvestAmount must be greater than zero when only sell is chosen");
        
    }
    
        // Check if floor and sell are chosen
        if (_parameter._floor && _parameter._sell) {
            require(_parameter._floorAt < _parameter._sellAt, "FloorValue must be less than SellAt");
        }

        // Check if floor and buy are chosen
        if (_parameter._floor && _parameter._buy) {
            require(_parameter._floorAt < _parameter._buyAt, "FloorValue must be less than BuyAt");
        }

        if (_parameter._buy && _parameter._sell && _parameter._stableAmount == 0 && _parameter._investAmount == 0) {
        revert("You should provide stableAmount or investAmount because you have chosen both buy and sell");
    }

    if (_parameter._sellType == SellLegType.INCREASE_BY &&(_parameter._str || _parameter._sellTwap)) {
        revert("With sell percentage, we cannot have DCA for sell");
    }

    if ( _parameter._floorType == FloorLegType.DECREASE_BY &&(_parameter._buyTwap || _parameter._btd)) {
        revert("With floor percentage, we cannot have DCA for buy");
    }

    if ( _parameter._buy && _parameter._buyTwap &&_parameter._btd) {
        revert("Both buy twap and BTD cannot be set together");
    }

    if (_parameter._sellTwap && _parameter._str) {
        revert("Both sell twap and str cannot be set together");
    }

    if ((_parameter._sellTwap || _parameter._str) &&_parameter._sellDCAUnit == DCA_UNIT.NO_UNIT) {
        revert("For sell twap and str, sell DCA unit must be provided");
    }

    if (_parameter._sellDCAUnit != DCA_UNIT.NO_UNIT && _parameter._sellDCAValue == 0) {
        revert("For sell DCA unit, sell DCA value must be provided");
    }

    if (_parameter._str && (_parameter._strValue == 0 || _parameter._strType == DIP_SPIKE.NO_SPIKE)) {
        revert("For str, str value and type must be provided");
    }

    if (_parameter._btd  && _parameter._btdType == DIP_SPIKE.NO_SPIKE) {
        revert("With BTD, type must be provided");
    }

    if (_parameter._btdType != DIP_SPIKE.NO_SPIKE && _parameter._btdValue == 0) {
        revert("With BTD type, BTD value must be provided");
    }

    if ((_parameter._btd || _parameter._buyTwap) && _parameter._buyDCAUnit == DCA_UNIT.NO_UNIT) {
        revert("With DCA buy, stable amount type must be provided. Whether fixed or percentage");
    }

    if (_parameter._buyDCAUnit != DCA_UNIT.NO_UNIT && _parameter._buyDCAValue == 0) {
        revert("With DCA, DCA value must be provided");
    }




        // s.strategies[s.nextStrategyId] = Strategy({
        //     investToken: _investToken,
        //     stableToken: _stableToken,
        //     buyAt: _buyAt,
        //     amount: _amount,
        //     user: msg.sender,
        //     slippage: _slippage,
        //     status: Status.ACTIVE
        // });

        s.nextStrategyId++;

        // emit StrategyCreated(_investToken, _stableToken, but, _amount);
    }

    function nextStartegyId() external view returns (uint256) {
        return s.nextStrategyId;
    }
}
