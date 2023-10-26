// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, BuyLegType, FloorLegType, CURRENT_PRICE, Swap } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, FloorGreaterThanPrice, WrongPreviousIDs } from "../utils/GenericErrors.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

error BuyNotSet();
error BuyDCAIsSet();
error BuyTwapNotSelected();
error ExpectedTimeNotElapsed();
error BTDNotSelected();
error RoundDataDoesNotMatch();

/**
 * @title BuyFacet
 * @notice This facet contains functions responsible for evaluating conditions necessary for executing buy actions.
 * @dev BuyFacet specializes in verifying conditions related to limit price buys and Dollar-Cost Averaging (DCA) buys,
 *      ensuring that the necessary criteria are met before executing a buy action.
 */

contract BuyFacet is Modifiers {
  /**
   * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
   * please look at AppStorage.sol for more detail
   */
  AppStorage internal s;

  /**
   * @notice Emitted when a buy action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
   * @param strategyId The unique ID of the strategy where the buy action was executed.
   * @param buyValue The value at which the buy action was executed.
   * @param executedAt Timestamp when the buy action was executed.
   */
  event BuyExecuted(
    uint256 indexed strategyId,
    uint256 buyValue,
    uint256 slippage,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );

  /**
   * @notice Emitted when a Buy on Time-Weighted Average Price (TWAP) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
   * @param strategyId The unique ID of the strategy where the Buy on TWAP action was executed.
   * @param buyValue The value at which the Buy on TWAP action was executed.
   * @param executedAt Timestamp when the Buy on TWAP action was executed.
   */
  event BuyTwapExecuted(
    uint256 indexed strategyId,
    uint256 buyValue,
    uint256 slipagge,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );
  /**
   * @notice Emitted when a Buy The Dip (BTD) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
   * @param strategyId The unique ID of the strategy where the BTD action was executed.
   * @param buyValue The value at which the BTD action was executed.
   * @param executedAt Timestamp when the BTD action was executed.
   */
  event BTDExecuted(
    uint256 indexed strategyId,
    uint256 buyValue,
    uint256 slipagge,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );

  /**
   * @notice Executes a buy action for a trading strategy based on specified conditions.
   * @dev The function validates strategy parameters, executes the buy action, and updates the strategy state.
   * @param strategyId The unique ID of the strategy for which the buy action is executed.
   * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
   */
  function executeBuy(uint256 strategyId, Swap calldata swap) external {
    Strategy storage strategy = s.strategies[strategyId];

    if (!strategy.parameters._buy) {
      revert BuyNotSet();
    }
    if (strategy.parameters._btd || strategy.parameters._buyTwap) {
      revert BuyDCAIsSet();
    }
    if (strategy.parameters._stableAmount == 0) {
      revert NoSwapFromZeroBalance();
    }
    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }
    transferBuy(
      strategy,
      strategyId,
      strategy.parameters._stableAmount,
      swap,
      price,
      investRoundId,
      stableRoundId,
      strategy.buyAt
    );

    if (!strategy.parameters._sell && !strategy.parameters._floor) {
      strategy.status = Status.COMPLETED;
    }

    strategy.investPrice = price;

    if (
      strategy.parameters._floor &&
      strategy.parameters._floorType == FloorLegType.DECREASE_BY
    ) {
      uint256 floorPercentage = 100 - strategy.parameters._floorValue;
      strategy.floorAt = (strategy.investPrice * floorPercentage) / 100;
    }
    if (
      strategy.parameters._sell &&
      strategy.parameters._sellType == SellLegType.INCREASE_BY
    ) {
      uint256 sellPercentage = 100 + strategy.parameters._sellValue;
      strategy.sellAt = (strategy.investPrice * sellPercentage) / 100;
    }
  }

  /**
   * @notice Executes a Buy on Time-Weighted Average Price (TWAP) action for a trading strategy.
   * @param strategyId The unique ID of the strategy to execute the Buy on TWAP action.
  * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.

 
   */
  function executeBuyTwap(uint256 strategyId, Swap calldata swap) external {
    Strategy storage strategy = s.strategies[strategyId];
    if (!strategy.parameters._buyTwap) {
      revert BuyTwapNotSelected();
    }
    if (strategy.parameters._stableAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );
    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }

    uint256 timeToExecute = LibTime.convertToSeconds(
      strategy.parameters._buyTwapTime,
      strategy.parameters._buyTwapTimeUnit
    );
    if (
      !LibTime.getTimeDifference(
        block.timestamp,
        strategy.buyTwapExecutedAt,
        timeToExecute
      )
    ) {
      revert ExpectedTimeNotElapsed();
    }

    uint256 value = 0;
    if (strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) {
      if (strategy.parameters._stableAmount > strategy.parameters._buyValue) {
        value = strategy.parameters._buyValue;
      } else {
        value = strategy.parameters._stableAmount;
      }
    } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
      value = strategy.buyPercentageAmount;
    }
    transferBuy(
      strategy,
      strategyId,
      value,
      swap,
      price,
      investRoundId,
      stableRoundId,
      strategy.buyAt
    );
    strategy.buyTwapExecutedAt = block.timestamp;
    if (
      !strategy.parameters._sell &&
      !strategy.parameters._floor &&
      strategy.parameters._stableAmount == 0
    ) {
      strategy.status = Status.COMPLETED;
    }

    strategy.totalBuyDCAInvestment = strategy.totalBuyDCAInvestment + value;

    uint256 previousValue = strategy.parameters._investAmount *
      strategy.investPrice;
    strategy.parameters._investAmount =
      strategy.parameters._investAmount +
      value;
    uint256 newValue = value * price;

    uint8 decimals = IERC20Metadata(strategy.parameters._stableToken)
    .decimals();
    strategy.investPrice =
      ((previousValue + newValue) * 10**uint256(decimals)) /
      strategy.parameters._investAmount;
    if (
      strategy.parameters._floor &&
      strategy.parameters._floorType == FloorLegType.DECREASE_BY
    ) {
      uint256 floorPercentage = 100 - strategy.parameters._floorValue;
      strategy.floorAt = (strategy.investPrice * floorPercentage) / 100;
    }
    if (
      strategy.parameters._sell &&
      strategy.parameters._sellType == SellLegType.INCREASE_BY
    ) {
      uint256 sellPercentage = 100 + strategy.parameters._sellValue;
      strategy.sellAt = (strategy.investPrice * sellPercentage) / 100;
    }
  }

  /**
   * @notice Executes a Buy-The-Dip (BTD) trading strategy action within a specified price range.
   * This function allows the strategy to buy the invest token when its price decreases to a certain target value, following a specified DIP strategy type.
   * @param strategyId The unique ID of the trading strategy where the BTD action is executed.
   * @param fromInvestRoundId The starting invest round ID for monitoring price fluctuations.
   * @param toInvestRoundId The ending invest round ID for monitoring price fluctuations.
   * @param fromStableRoundId The starting stable round ID for monitoring price fluctuations.
   * @param toStableRoundId The ending stable round ID for monitoring price fluctuations.
    * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
   
   */

  function executeBTD(
    uint256 strategyId,
    uint80 fromInvestRoundId,
    uint80 fromStableRoundId,
    uint80 toInvestRoundId,
    uint80 toStableRoundId,
    Swap calldata swap
  ) external {
    Strategy storage strategy = s.strategies[strategyId];
    if (!strategy.parameters._btd) {
      revert BTDNotSelected();
    }
    if (strategy.parameters._stableAmount == 0) {
      revert NoSwapFromZeroBalance();
    }
    checkRoundDataMistmatch(
      strategyId,
      fromInvestRoundId,
      fromStableRoundId,
      toInvestRoundId,
      toStableRoundId
    );
    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }

    uint256 buyValue = strategy.buyAt;
    if (strategy.btdLastTrackedPrice != 0) {
      buyValue = strategy.btdLastTrackedPrice;
    }

    uint256 value = 0;
    if (strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) {
      if (strategy.parameters._stableAmount > strategy.parameters._buyValue) {
        value = strategy.parameters._buyValue;
      } else {
        value = strategy.parameters._stableAmount;
      }
    } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
      value = strategy.buyPercentageAmount;
    }
    uint256 priceToBTD;
    if (strategy.btdLastTrackedPrice == 0) {
      if (price < buyValue) {
        strategy.btdLastTrackedPrice = price;
        transferBuy(
          strategy,
          strategyId,
          value,
          swap,
          price,
          investRoundId,
          stableRoundId,
          buyValue
        );
      }
    } else {
      if (
        strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY ||
        strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE
      ) {
        if (strategy.btdLastTrackedPrice > price) {
          strategy.btdLastTrackedPrice = price;
        } else if (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY) {
          priceToBTD =
            ((100 - strategy.parameters._btdValue) *
              strategy.btdLastTrackedPrice) /
            100;
          if (priceToBTD <= price) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              buyValue
            );
          }
        } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) {
          priceToBTD =
            strategy.btdLastTrackedPrice -
            strategy.parameters._btdValue;
          if (priceToBTD <= price) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              buyValue
            );
          }
        }
      } else if (
        strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY ||
        strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE
      ) {
        if (strategy.btdLastTrackedPrice < price) {
          strategy.btdLastTrackedPrice = price;
        } else if (strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY) {
          priceToBTD =
            ((100 + strategy.parameters._btdValue) *
              strategy.btdLastTrackedPrice) /
            100;
          if (price > strategy.buyAt) {
            strategy.btdLastTrackedPrice = price;
          } else if (priceToBTD >= price) {
            transferBuy(
              strategy,
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              buyValue
            );
            strategy.btdLastTrackedPrice = price;
          }
        } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) {
          priceToBTD =
            strategy.btdLastTrackedPrice +
            strategy.parameters._btdValue;

          if (price > strategy.buyAt) {
            strategy.btdLastTrackedPrice = price;
          } else if (priceToBTD >= strategy.btdLastTrackedPrice) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              buyValue
            );
          }
        }
      }
    }
    if (
      !strategy.parameters._sell &&
      !strategy.parameters._floor &&
      strategy.parameters._stableAmount == 0
    ) {
      strategy.status = Status.COMPLETED;
    }
    if (
      !strategy.parameters._sell &&
      !strategy.parameters._floor &&
      strategy.parameters._stableAmount == 0
    ) {
      strategy.status = Status.COMPLETED;
    }

    strategy.totalBuyDCAInvestment = strategy.totalBuyDCAInvestment + value;

    uint256 previousValue = strategy.parameters._investAmount *
      strategy.investPrice;
    strategy.parameters._investAmount =
      strategy.parameters._investAmount +
      value;
    uint256 newValue = value * price;

    uint8 decimals = IERC20Metadata(strategy.parameters._stableToken)
    .decimals();
    strategy.investPrice =
      ((previousValue + newValue) * 10**uint256(decimals)) /
      strategy.parameters._investAmount;
    if (
      strategy.parameters._floor &&
      strategy.parameters._floorType == FloorLegType.DECREASE_BY
    ) {
      uint256 floorPercentage = 100 - strategy.parameters._floorValue;
      strategy.floorAt = (strategy.investPrice * floorPercentage) / 100;
    }
    if (
      strategy.parameters._sell &&
      strategy.parameters._sellType == SellLegType.INCREASE_BY
    ) {
      uint256 sellPercentage = 100 + strategy.parameters._sellValue;
      strategy.sellAt = (strategy.investPrice * sellPercentage) / 100;
    }
  }

  /**
   * @notice Internal function to execute a "Buy" action within a specified price range.
   * @dev This function transfers assets from stable tokens to investment tokens on a DEX.
   * @param strategy The Strategy struct containing strategy parameters.
   * @param value The value to be transferred from stable tokens to investment tokens.
   * @param price The current price of the investment token.
   * @param investRoundId The invest round ID associated with the current price data.
   * @param stableRoundId The stable round ID associated with the current price data.
   * @param buyValue The target price at which the "Buy" action should be executed.
   */

  function transferBuy(
    Strategy memory strategy,
    uint256 strategyId,
    uint256 value,
    Swap memory swap,
    uint256 price,
    uint80 investRoundId,
    uint80 stableRoundId,
    uint256 buyValue
  ) internal {
    if (
      strategy.parameters._floor &&
      strategy.floorAt > 0 &&
      strategy.floorAt > price
    ) {
      revert FloorGreaterThanPrice();
    }
    LibSwap.SwapData memory swap1 = LibSwap.SwapData(
      swap.dex,
      strategy.parameters._stableToken,
      strategy.parameters._investToken,
      value,
      swap.callData,
      strategy.user
    );

    uint256 toTokenAmount = LibSwap.swap(swap1);

    uint256 rate = LibTrade.calculateExchangeRate(
      strategy.parameters._investToken,
      toTokenAmount,
      value
    );

    if (rate > buyValue) {
      revert InvalidExchangeRate(buyValue, rate);
    }
    strategy.timestamp = block.timestamp;
    strategy.parameters._investAmount += toTokenAmount;
    strategy.parameters._stableAmount -= value;
    strategy.investRoundId = investRoundId;
    strategy.stableRoundId = stableRoundId;
    if (
      (strategy.parameters._sellTwap || strategy.parameters._str) &&
      strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE
    ) {
      strategy.sellPercentageAmount =
        (strategy.parameters._sellDCAValue *
          strategy.parameters._investAmount) /
        100;
    }

    uint256 slippage = LibTrade.validateSlippage(
      rate,
      price,
      strategy.parameters._slippage,
      true
    );
    if (
      strategy.parameters._buy &&
      !strategy.parameters._btd &&
      !strategy.parameters._buyTwap
    ) {
      emit BuyExecuted(
        strategyId,
        price,
        slippage,
        toTokenAmount,
        rate,
        block.timestamp
      );
    } else if (strategy.parameters._btd) {
      emit BTDExecuted(
        strategyId,
        price,
        slippage,
        toTokenAmount,
        rate,
        block.timestamp
      );
    } else if (strategy.parameters._buyTwap) {
      emit BuyTwapExecuted(
        strategyId,
        price,
        slippage,
        toTokenAmount,
        rate,
        block.timestamp
      );
    }
  }

  /**
   * @notice Internal function to check if there is a data mismatch between price rounds for a strategy.
   * @dev This function ensures that the price fluctuations between specified rounds adhere to strategy parameters.
   * @param strategyId The unique ID of the trading strategy where the BTD action is executed.
   * @param fromInvestRoundId The round ID for the investment token's price data to start checking from.
   * @param fromStableRoundId The round ID for the stable token's price data to start checking from.
   * @param toInvestRoundId The round ID for the investment token's price data to check up to.
   * @param toStableRoundId The round ID for the stable token's price data to check up to.
   */
  function checkRoundDataMistmatch(
    uint256 strategyId,
    uint80 fromInvestRoundId,
    uint80 fromStableRoundId,
    uint80 toInvestRoundId,
    uint80 toStableRoundId
  ) internal view {
    Strategy storage strategy = s.strategies[strategyId];
    if (
      toInvestRoundId < fromInvestRoundId || toStableRoundId < fromStableRoundId
    ) {
      revert WrongPreviousIDs();
    }

    if (
      fromInvestRoundId == 0 ||
      toInvestRoundId == 0 ||
      strategy.strLastTrackedPrice == 0
    ) {
      return;
    }
    uint8 decimals = IERC20Metadata(strategy.parameters._stableToken)
    .decimals();
    int256 priceDecimals = int256(100 * (10**uint256(decimals)));

    uint256 fromPrice = LibPrice.getRoundData(
      fromInvestRoundId,
      fromStableRoundId,
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );
    uint256 toPrice = LibPrice.getRoundData(
      toInvestRoundId,
      toStableRoundId,
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );
    if (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) {
      if (
        !(int256(strategy.parameters._btdValue) >= int256(toPrice - fromPrice))
      ) {
        revert RoundDataDoesNotMatch();
      }
    } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) {
      if (
        !(int256(strategy.parameters._btdValue) >= int256(fromPrice - toPrice))
      ) {
        revert RoundDataDoesNotMatch();
      }
    } else if (strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY) {
      if (
        !(int256(strategy.parameters._btdValue) >=
          ((int256(toPrice - fromPrice) * priceDecimals) / int256(fromPrice)))
      ) {
        revert RoundDataDoesNotMatch();
      }
    } else if (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY) {
      if (
        !(int256(strategy.parameters._btdValue) >=
          ((int256(fromPrice - toPrice) * priceDecimals) / int256(fromPrice)))
      ) {
        revert RoundDataDoesNotMatch();
      }
    }
  }
}
