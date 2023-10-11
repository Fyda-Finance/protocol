// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy,StrategyParameters } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidSlippage } from "../utils/GenericErrors.sol";

contract StrategyFacet is Modifiers {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, uint256 buyAt, uint256 amount);

    function createStrategy(StrategyParameters memory _parameter) external {
        if (_parameter._slippage > MAX_PERCENTAGE) {
            revert InvalidSlippage();
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
