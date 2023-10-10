// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ScenarioERC20 } from "./ScenarioERC20.sol";

contract ScenarioDEX {

  // fromAsset => toAsset => exchangeRate
  mapping (address => mapping (address => uint256)) public exchangeRate;

  constructor() {}

  function updateExchangeRate(address fromAsset, address toAsset, uint256 rate) external {
    exchangeRate[fromAsset][toAsset] = rate;
  }

  function swap(
    address fromAsset,
    address toAsset,
    uint256 fromAmount
  ) external {
    require(exchangeRate[fromAsset][toAsset] > 0, "ScenarioDEX: exchange rate not set");
    require(fromAmount > 0, "ScenarioDEX: fromAmount must be greater than 0");

    uint256 toAmount = fromAmount * exchangeRate[fromAsset][toAsset];

    ScenarioERC20(toAsset).mint(address(this), toAmount);
    ScenarioERC20(fromAsset).transfer(msg.sender, toAmount);
  }
}