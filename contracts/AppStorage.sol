// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum Status {
        ACTIVE,
        CANCELLED,
        COMPLETED
}

enum FloorLegType {
  NO_TYPE,
  LIMIT_PRICE,
  DECREASE_BY
}

enum BuyLegType {
  NO_TYPE,
  LIMIT_PRICE,
  CURRENT_PRICE 
}
enum SellLegType {
  NO_TYPE,
  LIMIT_PRICE,
  INCREASE_BY,
  CURRENT_PRICE
}

enum DIP_SPIKE {
  NO_SPIKE,  
  DECREASE_BY,
  INCREASE_BY,
  FIXED_INCREASE,
  FIXED_DECREASE
}

enum DCA_UNIT {
  NO_UNIT,
  PERCENTAGE,
  FIXED
}

enum CURRENT_PRICE {
  NOT_SELECTED,
  BUY_CURRENT,
  SELL_CURRENT
}

enum TimeUnit {
  NO_UNIT,
  HOURS,
  DAYS
}

struct StrategyParameters{
   address _investToken;
    address _stableToken;
    uint256 _stableAmount;
    uint256 _investAmount;
    uint256 _slippage;
    bool _floor;
    FloorLegType _floorType;
    uint256 _floorAt;
    bool _liquidateOnFloor;
    bool _cancelOnFloor;
    bool _buy;
    BuyLegType _buyType;
    uint256 _buyAt;
    uint256 _buyValue;
    bool _sell;
    SellLegType _sellType;
    uint256 _sellAt;
    uint256 _highSellValue;
    bool _str;
    uint256 _strValue;
    DIP_SPIKE _strType;
    DCA_UNIT _sellDCAUnit;
    uint256 _sellDCAValue;
    bool _sellTwap;
    uint256 _sellTwapTime;
    TimeUnit _sellTwapTimeUnit;
    bool _completeOnSell;
    bool _buyTwap;
    uint256 _buyTwapTime;
    TimeUnit _buyTwapTimeUnit;
    bool _btd;
    uint256 _btdValue;
    DIP_SPIKE _btdType;
    DCA_UNIT _buyDCAUnit;
    uint256 _buyDCAValue;
}


struct Strategy {
    address user;
    StrategyParameters parameters;
    uint256 timestamp;
    Status status;

}


struct AppStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;

    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    
    // owner of the contract
    address owner;

    // next id to use for strategies
    uint256 nextStrategyId;

    // array of strategies
    mapping(uint256 => Strategy) strategies;

    // chainlink feed registry
    address chainlinkFeedRegistry;
}