// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate } from "../utils/GenericErrors.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TradeFacet {
    AppStorage internal s;

   

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

      uint256 toTokenAmount = LibSwap.swap(swap);
      uint256 rate = calculateExchangeRate(strategy.investToken, strategy.amount, toTokenAmount);

      if (rate > strategy.buyAt) {
        revert InvalidExchangeRate(
          strategy.buyAt,
          rate
        );
      }

      // now compare with chainlink
    }

    function calculateExchangeRate(
      address fromAsset,
      uint256 fromAmount,
      uint256 toAmount
    ) internal view returns (uint256) {
      IERC20Metadata _fromToken = IERC20Metadata(fromAsset);

      uint256 fromDecimals = _fromToken.decimals();

      // Let's take an example:
      // 2 ETHER or 2.2e18 (From Token Amount) = 3244,000000 USDC (To Token Amount)
      // 1 ETHER = 3244,000000 * 1e18 / 2000000000000000000 = 1622,000000 USDC

      return (toAmount * (10 ** fromDecimals) / fromAmount); 
    }
}
