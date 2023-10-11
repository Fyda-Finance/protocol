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

struct Strategy {
    address user;
    address investToken;
    address stableToken;
    uint256 stableAmount;
    uint256 investAmount;
    uint256 slippage;
    Status status;
    bool floor;
    FloorLegType floorType;
    uint256 floorValue;
    bool liquidateOnFloor;
    bool cancelOnFloor;
    bool buy;
    BuyLegType buyType;
    uint256 buyAt;
    uint256 buyValue;
    bool sell;
    SellLegType sellType;
    uint256 sellValue;
    uint256 highSellValue;
    bool str;
    uint256 strValue;
    DIP_SPIKE strType;
    DCA_UNIT sellDCAUnit;
    uint256 sellDCAValue;
    bool sellTwap;
    uint256 sellTwapTime;
    TimeUnit sellTwapTimeUnit;
    bool completeOnSell;
    bool buyTwap;
    uint256 buyTwapTime;
    TimeUnit buyTwapTimeUnit;
    bool btd;
    uint256 btdValue;
    DIP_SPIKE btdType;
    DCA_UNIT buyDCAUnit;
    uint256 buyDCAValue;
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