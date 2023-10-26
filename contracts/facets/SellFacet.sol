// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, CURRENT_PRICE, Swap } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, WrongPreviousIDs } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

error SellNotSelected();
error PriceLessThanHighSellValue();
error SellDCANotSelected();
error SellTwapNotSelected();
error ValueGreaterThanHighSellValue();
error TWAPTimeDifferenceIsLess();
error STRNotSelected();

/**
 * @title SellFacet
 * @notice This facet contains functions responsible for evaluating conditions for executing sell actions.
 * @dev SellFacet specializes in verifying conditions related to sell actions,
 * including limit price sells, Time-Weighted Average Price (TWAP) sells, and sell the rally criteria.
 *      It ensures that the necessary conditions are met before executing sell actions.
 */
contract SellFacet is Modifiers {
  /**
   * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
   * please look at AppStorage.sol for more detail
   */
  AppStorage internal s;

  /**
   * @notice Emitted when a sell action is executed for a trading strategy using a specific DEX and call data.
   * @param strategyId The unique ID of the strategy where the sell action is executed.
   * @param sellValue The value at which the  sell action was executed.
   * @param executedAt Timestamp when the sell action was executed.
   */
  event SellExecuted(
    uint256 indexed strategyId,
    uint256 sellValue,
    uint256 slippage,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );

  /**
   * @notice Emitted when a Time-Weighted Average Price (TWAP) sell action is executed for a trading strategy using a specific DEX and call data.
   * @param strategyId The unique ID of the strategy where the TWAP sell action was executed.
   * @param sellValue The value at which the TWAP sell action was executed.
   * @param executedAt Timestamp when the TWAP sell action was executed.
   */
  event SellTwapExecuted(
    uint256 indexed strategyId,
    uint256 sellValue,
    uint256 slippage,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );

  /**
   * @notice Emitted when a Spike Trigger (STR) event is executed for a trading strategy using a specific DEX and call data.
   * @param strategyId The unique ID of the strategy where the STR event was executed.
   * @param sellValue The value at which the STR event was executed.
   * @param executedAt Timestamp when the STR event was executed.
   */
  event STRExecuted(
    uint256 indexed strategyId,
    uint256 sellValue,
    uint256 slippage,
    uint256 amount,
    uint256 exchangeRate,
    uint256 executedAt
  );

  /**
   * @notice Execute a sell action for a trading strategy.
   * @dev This function performs a sell action based on the specified strategy parameters and market conditions.
   *      It verifies whether the strategy's parameters meet the required conditions for executing a sell.
   * @param strategyId The unique ID of the strategy to execute the sell action for.
  * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.


   */
  function executeSell(uint256 strategyId, Swap calldata swap) external {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Ensure that selling is selected in the strategy parameters.
    if (!strategy.parameters._sell) {
      revert SellNotSelected();
    }

    // Ensure that there is invest token available for selling.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // Retrieve the latest price and round ID from Chainlink.
    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    // Check the current price source selected in the strategy parameters.
    if (strategy.parameters.current_price == CURRENT_PRICE.SELL_CURRENT) {
      // Set the sell value to the current price.
      strategy.parameters._sellValue = price;
      strategy.sellAt = price;
      strategy.parameters._sellType = SellLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }

    // Determine the sell value based on strategy parameters and market conditions.
    uint256 sellValue = strategy.sellAt;

    if (
      strategy.parameters._highSellValue != 0 &&
      (strategy.parameters._str || strategy.parameters._sellTwap)
    ) {
      // If a high sell value is specified and "strategy" or "sell TWAP" is selected, use the high sell value.
      sellValue = strategy.parameters._highSellValue;
      if (price < sellValue) {
        revert PriceLessThanHighSellValue();
      }
    } else if (strategy.parameters._str || strategy.parameters._sellTwap) {
      // If neither high sell value nor "sell the rally" nor "sell TWAP" is selected, throw an error.
      revert SellDCANotSelected();
    }

    // Perform the sell action, including transferring assets to the DEX.
    transferSell(
      strategyId,
      strategy.parameters._investAmount,
      swap,
      price,
      investRoundId,
      stableRoundId,
      sellValue
    );

    // If there are no further buy actions in the strategy, mark it as completed.
    if (!strategy.parameters._buy) {
      strategy.status = Status.COMPLETED;
    }
  }

  /**
   * @notice Execute a Time-Weighted Average Price (TWAP) sell action for a trading strategy.
   * @dev This function performs a TWAP sell action based on the specified strategy parameters and market conditions.
   *      It verifies whether the strategy's parameters meet the required conditions for executing a TWAP sell.
   * @param strategyId The unique ID of the strategy to execute the TWAP sell action for.
   * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.

   */
  function executeSellTwap(uint256 strategyId, Swap calldata swap) external {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Ensure that TWAP sell is selected in the strategy parameters.
    if (!strategy.parameters._sellTwap) {
      revert SellTwapNotSelected();
    }

    // Ensure that there is invest token available for selling.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // Retrieve the latest price and round ID from Chainlink.
    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    // Check the current price source selected in the strategy parameters.
    if (strategy.parameters.current_price == CURRENT_PRICE.SELL_CURRENT) {
      // Set the sell value to the current price.
      strategy.parameters._sellValue = price;
      strategy.sellAt = price;
      strategy.parameters._sellType = SellLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }

    // Initialize value for the TWAP sell.
    uint256 value = 0;

    if (strategy.parameters._sellDCAUnit == DCA_UNIT.FIXED) {
      // If the TWAP sell unit is fixed, determine the value based on strategy parameters.
      if (strategy.parameters._investAmount > strategy.parameters._sellValue) {
        value = strategy.parameters._sellValue;
      } else {
        value = strategy.parameters._investAmount;
      }
    } else if (strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
      value = strategy.sellPercentageAmount;
    }

    if (
      strategy.parameters._highSellValue != 0 &&
      price > strategy.parameters._highSellValue
    ) {
      revert ValueGreaterThanHighSellValue();
    }

    // Calculate the time interval for TWAP execution and check if it can be executed.
    uint256 timeToExecute = LibTime.convertToSeconds(
      strategy.parameters._sellTwapTime,
      strategy.parameters._sellTwapTimeUnit
    );

    if (
      !LibTime.getTimeDifference(
        block.timestamp,
        strategy.sellTwapExecutedAt,
        timeToExecute
      )
    ) {
      revert TWAPTimeDifferenceIsLess();
    }

    // Update the TWAP execution timestamp and perform the TWAP sell action.
    strategy.sellTwapExecutedAt = block.timestamp;
    transferSell(
      strategyId,
      value,
      swap,
      price,
      investRoundId,
      stableRoundId,
      strategy.sellAt
    );

    // Mark the strategy as completed if there are no further buy actions and no assets left to invest.
    if (!strategy.parameters._buy && strategy.parameters._investAmount == 0) {
      strategy.status = Status.COMPLETED;
    }
  }

  /**
   * @notice Execute a strategy based on Spike Trigger (STR) conditions for a trading strategy.
   * @dev This function performs actions based on the specified strategy parameters and market conditions to execute Sell The Rally (STR) events.
   *      It verifies whether the strategy's parameters meet the required conditions for executing STR events.
   * @param strategyId The unique ID of the strategy to execute the STR actions for.
   * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
   * @param fromInvestRoundId The starting invest round ID for price data.
   * @param toInvestRoundId The ending invest round ID for price data.
   * @param fromStableRoundId The starting stable round ID for price data.
   * @param toStableRoundId The ending stable round ID for price data.
   
   */
  function executeSTR(
    uint256 strategyId,
    Swap calldata swap,
    uint80 fromInvestRoundId,
    uint80 fromStableRoundId,
    uint80 toInvestRoundId,
    uint80 toStableRoundId
  ) public {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Ensure that STR events are selected in the strategy parameters.
    if (!strategy.parameters._str) {
      revert STRNotSelected();
    }

    // Ensure that there is invest token available for selling.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // Retrieve the latest price and round ID from Chainlink.
    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    // Check the current price source selected in the strategy parameters.
    if (strategy.parameters.current_price == CURRENT_PRICE.SELL_CURRENT) {
      strategy.parameters._sellValue = price;
      strategy.sellAt = price;
      strategy.parameters._sellType = SellLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.EXECUTED;
    }

    // Initialize high sell value for STR events.
    uint256 highSellValue = strategy.parameters._highSellValue;
    if (strategy.parameters._highSellValue == 0) {
      highSellValue = type(uint256).max;
    }
    checkRoundDataMistmatch(
      strategyId,
      fromInvestRoundId,
      fromStableRoundId,
      toInvestRoundId,
      toStableRoundId
    );
    uint256 sellValue = strategy.sellAt;
    if (strategy.strLastTrackedPrice != 0) {
      sellValue = strategy.strLastTrackedPrice;
    }
    uint256 value = 0;
    if (strategy.parameters._sellDCAUnit == DCA_UNIT.FIXED) {
      if (strategy.parameters._investAmount > strategy.parameters._sellValue) {
        value = strategy.parameters._sellValue;
      } else {
        value = strategy.parameters._investAmount;
      }
    } else if (strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
      value = strategy.sellPercentageAmount;
    }

    uint256 priceToSTR;
    if (strategy.strLastTrackedPrice == 0) {
      if (price >= sellValue && price < highSellValue) {
        transferSell(
          strategyId,
          value,
          swap,
          price,
          investRoundId,
          stableRoundId,
          sellValue
        );
        strategy.strLastTrackedPrice = price;
      }
    } else {
      if (
        strategy.parameters._strType == DIP_SPIKE.DECREASE_BY ||
        strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE
      ) {
        if (sellValue > price) {
          strategy.strLastTrackedPrice = price;
        } else if (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY) {
          priceToSTR =
            ((100 - strategy.parameters._strValue) *
              strategy.strLastTrackedPrice) /
            100;
          if (priceToSTR <= price) {
            transferSell(
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              sellValue
            );
            strategy.strLastTrackedPrice = price;
          }
        } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
          priceToSTR = sellValue - strategy.parameters._strValue;
          if (priceToSTR <= price) {
            transferSell(
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              sellValue
            );
            strategy.strLastTrackedPrice = price;
          }
        }
      } else if (
        strategy.parameters._strType == DIP_SPIKE.INCREASE_BY ||
        strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE
      ) {
        if (strategy.strLastTrackedPrice < price) {
          strategy.strLastTrackedPrice = price;
        } else if (strategy.parameters._strType == DIP_SPIKE.INCREASE_BY) {
          priceToSTR =
            ((100 + strategy.parameters._strValue) * sellValue) /
            100;
          if (priceToSTR >= price && !(price >= highSellValue)) {
            transferSell(
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              sellValue
            );
          }
          strategy.strLastTrackedPrice = price;
        } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
          priceToSTR = sellValue + strategy.parameters._strValue;

          if (priceToSTR >= sellValue && !(price > highSellValue)) {
            transferSell(
              strategyId,
              value,
              swap,
              price,
              investRoundId,
              stableRoundId,
              sellValue
            );
          }
          strategy.strLastTrackedPrice = price;
        }
      }
    }
    // Mark the strategy as completed if there are no further buy actions and no assets left to invest.

    if (!strategy.parameters._buy && strategy.parameters._investAmount == 0) {
      strategy.status = Status.COMPLETED;
    }
  }

  /**
   * @notice Transfer assets from the trading strategy during a sell action.
   * @dev This function swaps a specified amount of assets on a DEX (Decentralized Exchange) and updates the strategy's state accordingly.
   * @param value The amount to be sold on the DEX.
   * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
   * @param price The current market price of the investment token.
   * @param investRoundId The round ID for invest price data.
   * @param stableRoundId The round ID for stable price data.
   * @param sellValue The value at which the sell action was executed.
   */
  function transferSell(
    uint256 strategyId,
    uint256 value,
    Swap calldata swap,
    uint256 price,
    uint80 investRoundId,
    uint80 stableRoundId,
    uint256 sellValue
  ) internal {
    Strategy storage strategy = s.strategies[strategyId];

    // Create a swap data structure for the DEX trade.
    LibSwap.SwapData memory swap1 = LibSwap.SwapData(
      swap.dex,
      strategy.parameters._investToken,
      strategy.parameters._stableToken,
      value,
      swap.callData,
      strategy.user
    );

    // Perform the asset swap on the DEX and calculate the exchange rate.
    uint256 toTokenAmount = LibSwap.swap(swap1);

    uint256 rate = LibTrade.calculateExchangeRate(
      strategy.parameters._investToken,
      value,
      toTokenAmount
    );
    // Check if the exchange rate meets the specified sell value.
    if (rate < sellValue) {
      revert InvalidExchangeRate(sellValue, rate);
    }

    // Validate slippage if the strategy is not an STR (Spike Trigger).
    uint256 slippage = 0;
    if (!strategy.parameters._str) {
      slippage = LibTrade.validateSlippage(
        rate,
        price,
        strategy.parameters._slippage,
        false
      );
    }

    // Calculate the total investment amount and check if it exceeds the budget.

    strategy.totalSellDCAInvestment =
      strategy.totalSellDCAInvestment +
      toTokenAmount;
    strategy.parameters._investAmount =
      strategy.parameters._investAmount -
      value;
    strategy.parameters._stableAmount =
      strategy.parameters._stableAmount +
      toTokenAmount;

    uint256 sum = strategy.parameters._stableAmount +
      strategy.parameters._investAmount *
      strategy.investPrice;

    if (strategy.budget < sum) {
      strategy.parameters._stableAmount =
        strategy.budget -
        strategy.parameters._investAmount *
        strategy.investPrice;

      strategy.profit = sum - strategy.budget + strategy.profit;
    }

    // Update the strategy's timestamp, buy percentage amount, and round ID if necessary.

    strategy.timestamp = block.timestamp;
    strategy.parameters._investAmount -= value;
    strategy.parameters._stableAmount += toTokenAmount;
    strategy.investRoundId = investRoundId;
    strategy.stableRoundId = stableRoundId;
    // Calculate the buy percentage amount if buy actions are based on TWAP or BTD.
    if (
      (strategy.parameters._buyTwap || strategy.parameters._btd) &&
      strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE
    ) {
      strategy.buyPercentageAmount =
        (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) /
        100;
    }
    if (
      (strategy.parameters._sell &&
        !strategy.parameters._str &&
        !strategy.parameters._sellTwap) ||
      (strategy.parameters._sell && strategy.parameters._highSellValue > price)
    ) {
      emit SellExecuted(
        strategyId,
        sellValue,
        slippage,
        toTokenAmount,
        rate,
        block.timestamp
      );
    } else if (strategy.parameters._str) {
      emit STRExecuted(
        strategyId,
        price,
        slippage,
        toTokenAmount,
        rate,
        block.timestamp
      );
    } else if (strategy.parameters._sellTwap) {
      emit SellTwapExecuted(
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
   * @param strategyId The unique ID of the strategy to execute the STR actions for.
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
    if (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
      if (
        !(int256(strategy.parameters._strValue) >= int256(toPrice - fromPrice))
      ) {
        revert();
      }
    } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
      if (
        !(int256(strategy.parameters._strValue) >= int256(fromPrice - toPrice))
      ) {
        revert();
      }
    } else if (strategy.parameters._strType == DIP_SPIKE.INCREASE_BY) {
      if (
        !(int256(strategy.parameters._strValue) >=
          ((int256(toPrice - fromPrice) * priceDecimals) / int256(fromPrice)))
      ) {
        revert();
      }
    } else if (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY) {
      if (
        !(int256(strategy.parameters._strValue) >=
          ((int256(fromPrice - toPrice) * priceDecimals) / int256(fromPrice)))
      ) {
        revert();
      }
    }
  }
}
