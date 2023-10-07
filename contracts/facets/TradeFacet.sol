// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorage, Strategy } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";

contract TradeFacet {
    AppStorage internal s;

    event StrategyCreated(address indexed investToken, address indexed stableToken, uint256 buyAt, uint256 amount);

    function executeBuy(uint256 strategyId, address dex, bytes calldata callData) external {
      Strategy storage strategy = s.strategies[strategyId];

      LibSwap.SwapData memory swap = LibSwap.SwapData(
        dex,
        strategy.stableToken,
        strategy.investToken,
        strategy.amount,
        callData,
        strategy.user
      );

      LibSwap.swap(swap);

      // calculate exchange rate and then compare with chainlink
    }
}
