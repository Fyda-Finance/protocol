// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorage, Strategy } from "../AppStorage.sol";

contract StrategyFacet {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, uint256 buyAt, uint256 amount);

    function createStrategy(address _investToken, address _stableToken, uint256 _buyAt, uint256 _amount) external {
        s.strategies[s.nextStrategyId] = Strategy({
            investToken: _investToken,
            stableToken: _stableToken,
            buyAt: _buyAt,
            amount: _amount,
            user: msg.sender
        });

        s.nextStrategyId++;

        emit StrategyCreated(_investToken, _stableToken, _buyAt, _amount);
    }
}
