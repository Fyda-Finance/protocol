// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice The `Status` enum represents the possible statuses of a trading strategy.
 * @dev This enum defines three status options that describe the state of a strategy:
 *      - ACTIVE: The strategy is currently active and operational.
 *      - CANCELLED: The strategy has been cancelled and is no longer in effect.
 *      - COMPLETED: The strategy has been successfully completed.
 */
enum Status {
    ACTIVE, // The strategy is currently active.
    CANCELLED, // The strategy has been cancelled.
    COMPLETED // The strategy has been successfully completed.
}

/**
 * @notice The `FloorLegType` enum defines the types of floor price legs for trading strategies.
 * @dev This enum enumerates three possible types of floor price legs that can be associated with a strategy:
 *      - NO_TYPE: No specific floor price leg is defined.
 *      - LIMIT_PRICE: The floor price is set as a specific limit price.
 *      - DECREASE_BY: The floor price is determined by decreasing the current price by a certain amount.
 */
enum FloorLegType {
    NO_TYPE, // No specific floor price leg is defined.
    LIMIT_PRICE, // The floor price is set as a specific limit price.
    DECREASE_BY // The floor price is determined by decreasing the current price by a certain amount.
}
/**
 * @notice The `BuyLegType` enum defines the types of buy legs for trading strategies.
 * @dev This enum enumerates two possible types of buy legs that can be associated with a strategy:
 *      - NO_TYPE: No specific buy leg is defined.
 *      - LIMIT_PRICE: The buy leg is set as a specific limit price.
 */
enum BuyLegType {
    NO_TYPE, // No specific buy leg is defined.
    LIMIT_PRICE // The buy leg is set as a specific limit price.
}

/**
 * @notice The `SellLegType` enum defines the types of sell legs for trading strategies.
 * @dev This enum enumerates three possible types of sell legs that can be associated with a strategy:
 *      - NO_TYPE: No specific sell leg is defined.
 *      - LIMIT_PRICE: The sell leg is set as a specific limit price.
 *      - INCREASE_BY: The sell leg is determined by increasing the current price by a certain amount.
 */
enum SellLegType {
    NO_TYPE, // No specific sell leg is defined.
    LIMIT_PRICE, // The sell leg is set as a specific limit price.
    INCREASE_BY // The sell leg is determined by increasing the current price by a certain amount.
}

/**
 * @notice The `DIP_SPIKE` enum defines the types of dip and spike conditions for trading strategies.
 * @dev This enum enumerates five possible types of dip and spike conditions that can be associated with a strategy:
 *      - NO_SPIKE: No specific dip or spike condition is defined.
 *      - DECREASE_BY: The condition is based on a decrease in price by a certain percentage.
 *      - INCREASE_BY: The condition is based on an increase in price by a certain percentage.
 *      - FIXED_INCREASE: The condition is based on a fixed increase in price.
 *      - FIXED_DECREASE: The condition is based on a fixed decrease in price.
 */
enum DIP_SPIKE {
    NO_SPIKE, // No specific dip or spike condition is defined.
    DECREASE_BY, // The condition is based on a decrease in price by a certain percentage.
    INCREASE_BY, // The condition is based on an increase in price by a certain percentage.
    FIXED_INCREASE, // The condition is based on a fixed increase in price.
    FIXED_DECREASE // The condition is based on a fixed decrease in price.
}

/**
 * @notice The `DCA_UNIT` enum defines the units for Dollar-Cost Averaging (DCA) in trading strategies.
 * @dev This enum enumerates three possible units for DCA that can be associated with a strategy:
 *      - NO_UNIT: No specific DCA unit is defined.
 *      - PERCENTAGE: DCA is specified as a percentage of assets.
 *      - FIXED: DCA is specified as a fixed amount.
 */
enum DCA_UNIT {
    NO_UNIT, // No specific DCA unit is defined.
    PERCENTAGE, // DCA is specified as a percentage of assets.
    FIXED // DCA is specified as a fixed amount.
}

/**
 * @notice The `CURRENT_PRICE` enum defines the options for selecting the current price source in trading strategies.
 * @dev This enum enumerates four possible options for selecting the current price source:
 *      - NOT_SELECTED: No specific current price source is selected.
 *      - BUY_CURRENT: The current price source is selected for buy actions.
 *      - SELL_CURRENT: The current price source is selected for sell actions.
 */
enum CURRENT_PRICE {
    NOT_SELECTED, // No specific current price source is selected.
    BUY_CURRENT, // The current price source is selected for buy actions.
    SELL_CURRENT // The current price source is selected for sell actions.
}

/**
 * @notice The `TimeUnit` enum defines the units of time for time-related settings in trading strategies.
 * @dev This enum enumerates three possible time units that can be used in trading strategies:
 *      - NO_UNIT: No specific time unit is defined.
 *      - HOURS: Time is measured in hours.
 *      - DAYS: Time is measured in days.
 */
enum TimeUnit {
    NO_UNIT, // No specific time unit is defined.
    HOURS, // Time is measured in hours.
    DAYS // Time is measured in days.
}

/**
 * @notice The `StrategyParameters` struct defines the parameters that configure a trading strategy.
 * @dev These parameters dictate the behavior of the strategy, including trading details, conditions, and actions.
 */

struct StrategyParameters {
    // @param _investToken The address of the investment token.
    address _investToken;
    // @param _investAmount The amount of investment token to be used.
    uint256 _investAmount;
    // @param _stableToken The address of the stable token.
    address _stableToken;
    // @param _stableAmount The amount of stable token to be used.
    uint256 _stableAmount;
    // @param _slippage The slippage tolerance for the strategy.
    uint256 _slippage;
    //  @param _floor A flag indicating whether a floor price is set.
    bool _floor;
    // @param _floorType The type of floor price (if floor is set).
    FloorLegType _floorType;
    // @param _floorValue The value of the floor price (if floor is set).
    uint256 _floorValue;
    // @param _liquidateOnFloor A flag to trigger liquidation when the floor price is reached (if floor is set)..
    bool _liquidateOnFloor;
    // @param _cancelOnFloor A flag to cancel the strategy when the floor price is reached (if floor is set).
    bool _cancelOnFloor;
    // @param _buy A flag indicating whether a buy price is set.
    bool _buy;
    // @param _buyType The type of buy action (if buy is set).
    BuyLegType _buyType;
    // @param _buyValue The value of the buy action (if buy is set).
    uint256 _buyValue;
    //  @param _buyTwap A flag indicating the use of TWAP for buying (if buy is set).
    bool _buyTwap;
    // @param _buyTwapTime The time interval for TWAP buying (if buy is set).
    uint256 _buyTwapTime;
    // @param _buyTwapTimeUnit The unit of time for TWAP buying .
    TimeUnit _buyTwapTimeUnit;
    // @param _btd A flag indicating a buy the dip action (if buy is set).
    bool _btd;
    // @param _btdValue The value for buying the dip (if buy is set).
    uint256 _btdValue;
    // @param _btdType The type of buy the dip action (if buy is set).
    DIP_SPIKE _btdType;
    // @param _buyDCAUnit The unit for buy DCA (Dollar-Cost Averaging) for stable amount (if buy is set).
    DCA_UNIT _buyDCAUnit;
    // @param _buyDCAValue The value for buy DCA.
    uint256 _buyDCAValue;
    // @param _sell A flag indicating whether a sell price is set.
    bool _sell;
    // @param _sellType The type of sell action (if sell is set).
    SellLegType _sellType;
    // @param _sellValue The value of the sell action (if sell is set).
    uint256 _sellValue;
    // @param if sell DCA is selected, _highSellValue is used to trigger complete sell when the high sell value is reached (if sell is set).
    uint256 _highSellValue;
    // @param _str A flag indicating whether Sell the rally feature of the Sell DCA is selected or not (if sell is set).
    bool _str;
    // @param _strValue The value of the str if it is set to true (if sell is set).
    uint256 _strValue;
    // @param _strType The type of str.
    DIP_SPIKE _strType;
    // @param _sellDCAUnit The unit for sell DCA (Dollar-Cost Averaging) for the invest amount (if sell is set).
    DCA_UNIT _sellDCAUnit;
    // @param _sellDCAValue The value for sell DCA.
    uint256 _sellDCAValue;
    // @param _sellTwap A flag indicating the use of TWAP (Time-Weighted Average Price) for selling (if sell is set).
    bool _sellTwap;
    // @param _sellTwapTime The time interval for TWAP selling (if sell is set).
    uint256 _sellTwapTime;
    //  @param _sellTwapTimeUnit The unit of time for TWAP selling (if sell is set).
    TimeUnit _sellTwapTimeUnit;
    // @param _completeOnSell A flag to complete the strategy on selling (if sell is set).
    bool _completeOnSell;
    // @param _current_price The current price indicator is selected what kind of strategy to execute immediately.
    CURRENT_PRICE _current_price;
}

/**
 * @notice The `Strategy` struct defines the characteristics and status of a trading strategy.
 * @dev This struct encapsulates important data related to a trading strategy, including user ownership,
 *      strategy parameters, execution times, financial metrics, and its current status.
 * it is mostly used for internal computation
 */

struct Strategy {
    //  @param user The address of the strategy owner.
    address user;
    // @param parameters The parameters that configure the behavior of the strategy
    // as passed by the user and defined above
    StrategyParameters parameters;
    //  @param sellTwapExecutedAt The timestamp of the last executed TWAP (Time-Weighted Average Price) sell.
    //  if sell twap is set for the sell. Otherwise it remains 0
    uint256 sellTwapExecutedAt;
    //  @param buyTwapExecutedAt The timestamp of the last executed TWAP buy.
    //  if buy Twap is set for btd. Otherwise it remains 0.
    uint256 buyTwapExecutedAt;
    // @param invest roundId The Chainlink VRF (Verifiable Random Function) round ID.
    uint80 investRoundId;
    // @param stable roundId The Chainlink VRF (Verifiable Random Function) round ID.
    uint80 stableRoundId;
    // @param investPrice The price at which investment is made.
    //While creating strategy it is set to the current price
    uint256 investPrice;
    //  @param profit The current profit generated by the strategy.
    uint256 profit;
    //  @param budget The available budget for the strategy.
    // it is set at the starting of the strategy
    uint256 budget;
    // @param status The current status of the strategy.
    Status status;
}
/**
 * @notice AppStorage is the central storage structure for this contract, holding essential data.
 * @dev This struct contains critical information used by the contract for operation.
 * It stores data such as function selectors, supported interfaces, the contract owner, strategy details,
 * Chainlink feed information, and more.
 */

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
    // chainlink feeds - asset => USD feed
    mapping(address => address) feeds;
    // account => nonce
    mapping(address => uint256) nonces;
}

/**
 * @title Swap
 * @dev A struct representing a swap or trade operation on a decentralized exchange (DEX).
 *  @param dex: The address of the DEX where the swap is to be executed.
 *  @param callData: Encoded data containing instructions for the swap on the specified DEX.
 */
struct Swap {
    address dex;
    bytes callData;
}

// Struct representing the parameters to update in a strategy
struct UpdateStruct {
    uint256 sellLimitPrice;
    uint256 sellPercentageValue;
    uint256 buyLimitPrice;
    uint256 floorPercentageValue;
    uint256 floorLimitPrice;
    uint256 highSellValue;
    uint256 _buyTwapTime;
    TimeUnit _buyTwapTimeUnit;
    uint256 _buyDCAValue;
    uint256 _sellDCAValue;
    uint256 _sellTwapTime;
    TimeUnit _sellTwapTimeUnit;
    bool toggleCompleteOnSell;
    bool toggleLiquidateOnFloor;
    bool toggleCancelOnFloor;
    CURRENT_PRICE _current_price;
}
