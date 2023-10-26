// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ScenarioFeedAggregator {
  // price in USD -> 8 decimals
  int256 public price;

  function setPrice(int256 _price) external {
    price = _price;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (roundId, price, 0, 0, 0);
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (0, price, 0, 0, 0);
  }
}
