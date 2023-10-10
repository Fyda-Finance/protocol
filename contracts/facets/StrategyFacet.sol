// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidSlippage } from "../utils/GenericErrors.sol";

contract StrategyFacet is Modifiers {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, uint256 buyAt, uint256 amount);

    function createStrategy(address _investToken, address _stableToken, uint256 _buyAt, uint256 _amount, uint256 _slippage) external {
        if (_slippage > MAX_PERCENTAGE) {
            revert InvalidSlippage();
        }

        s.strategies[s.nextStrategyId] = Strategy({
            investToken: _investToken,
            stableToken: _stableToken,
            buyAt: _buyAt,
            amount: _amount,
            user: msg.sender,
            slippage: _slippage
        });

        s.nextStrategyId++;

        emit StrategyCreated(_investToken, _stableToken, _buyAt, _amount);
    }

    function nextStartegyId() external view returns (uint256) {
        return s.nextStrategyId;
    }
}
