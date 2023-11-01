// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ScenarioFeedAggregator {
    // price in USD -> 8 decimals
    int256 public price;
    uint80 public roundId;
    mapping(uint80 => uint256) public roundPrice;

    function setPrice(int256 _price, uint80 _roundId) external {
        price = _price;
        roundId = _roundId;
    }

    function setRoundPrice(uint80 _roundId, uint256 _price) external {
        roundPrice[_roundId] = _price;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if (roundPrice[_roundId] != 0) {
            return (_roundId, int256(roundPrice[_roundId]), 0, 0, 0);
        } else {
            return (_roundId, int256(0), 0, 0, 0);
        }
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (roundId, price, 0, 0, 0);
    }
}
