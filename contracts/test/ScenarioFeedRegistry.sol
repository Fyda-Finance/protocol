// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract ScenarioFeedRegistry {
  // asset => price in USD -> 8 decimals
  mapping (address => int) public price;

  function latestRoundData(address base) external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
      return (0, price[base], 0,0,0);
    }

  function updatePrice(
    address base,
    int _price
  ) external {
    price[base] = _price;
  }
}