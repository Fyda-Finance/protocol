// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../utils/Modifiers.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

contract LensFacet is Modifiers {
  function calculateExchangeRate(
    address fromAsset,
    uint256 fromAmount,
    uint256 toAmount
  ) external view returns (uint256) {
    return LibTrade.calculateExchangeRate(fromAsset, fromAmount, toAmount);
  }

  function validateSlippage(
    uint256 exchangeRate,
    uint256 price,
    uint256 maxSlippage,
    bool isBuy
  ) external pure returns (uint256) {
    return LibTrade.validateSlippage(exchangeRate, price, maxSlippage, isBuy);
  }
}
