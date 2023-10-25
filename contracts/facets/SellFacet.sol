// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, CURRENT_PRICE } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

error SellNotSelected();
error PriceLessThanHighSellValue();
error SellDCANotSelected();

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
   * @param dex The address of the DEX used for the execution.
   * @param callData The calldata for interacting with the DEX.
   * @param sellValue The value at which the  sell action was executed.
   * @param executedAt Timestamp when the sell action was executed.
   */
  event SellExecuted(
    uint256 indexed strategyId,
    address dex,
    bytes callData,
    uint256 sellValue,
    uint256 executedAt
  );

  /**
   * @notice Emitted when a Time-Weighted Average Price (TWAP) sell action is executed for a trading strategy using a specific DEX and call data.
   * @param strategyId The unique ID of the strategy where the TWAP sell action was executed.
   * @param dex The address of the DEX used for the execution.
   * @param callData The calldata for interacting with the DEX.
   * @param sellValue The value at which the TWAP sell action was executed.
   * @param executedAt Timestamp when the TWAP sell action was executed.
   */
  event SellTwapExecuted(
    uint256 indexed strategyId,
    address dex,
    bytes callData,
    uint256 sellValue,
    uint256 executedAt
  );

  /**
   * @notice Emitted when a Spike Trigger (STR) event is executed for a trading strategy using a specific DEX and call data.
   * @param strategyId The unique ID of the strategy where the STR event was executed.
   * @param dex The address of the DEX used for the execution.
   * @param callData The calldata for interacting with the DEX.
   * @param sellValue The value at which the STR event was executed.
   * @param executedAt Timestamp when the STR event was executed.
   */
  event STRExecuted(
    uint256 indexed strategyId,
    address dex,
    bytes callData,
    uint256 sellValue,
    uint256 executedAt
  );

  /**
   * @notice Execute a sell action for a trading strategy.
   * @dev This function performs a sell action based on the specified strategy parameters and market conditions.
   *      It verifies whether the strategy's parameters meet the required conditions for executing a sell.
   * @param strategyId The unique ID of the strategy to execute the sell action for.
   * @param dex The address of the DEX (Decentralized Exchange) to use for the sell action.
   * @param callData The calldata for interacting with the DEX.
   */
  function executeSell(
    uint256 strategyId,
    address dex,
    bytes calldata callData
  ) external {
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
    (uint256 price, uint80 roundId) = LibPrice.getPrice(
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
      if (price < strategy.parameters._highSellValue) {
        revert PriceLessThanHighSellValue();
      }
    } else if (strategy.parameters._str || strategy.parameters._sellTwap) {
      // If neither high sell value nor "strategy" nor "sell TWAP" is selected, throw an error.
      revert SellDCANotSelected();
    }

    // Perform the sell action, including transferring assets to the DEX.
    transferSell(
      strategy,
      strategy.parameters._investAmount,
      dex,
      callData,
      price,
      roundId,
      sellValue
    );

    // If there are no further buy actions in the strategy, mark it as completed.
    if (!strategy.parameters._buy) {
      strategy.status = Status.COMPLETED;
    }

    emit SellExecuted(strategyId, dex, callData, price, block.timestamp);
  }

  /**
   * @notice Execute a Time-Weighted Average Price (TWAP) sell action for a trading strategy.
   * @dev This function performs a TWAP sell action based on the specified strategy parameters and market conditions.
   *      It verifies whether the strategy's parameters meet the required conditions for executing a TWAP sell.
   * @param strategyId The unique ID of the strategy to execute the TWAP sell action for.
   * @param dex The address of the DEX (Decentralized Exchange) to use for the TWAP sell action.
   * @param callData The calldata for interacting with the DEX.
   */
  function executeSellTwap(
    uint256 strategyId,
    address dex,
    bytes calldata callData
  ) external {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Ensure that TWAP sell is selected in the strategy parameters.
    if (!strategy.parameters._sellTwap) {
      revert();
    }

    // Ensure that there is invest token available for selling.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // Retrieve the latest price and round ID from Chainlink.
    (uint256 price, uint80 roundId) = LibPrice.getPrice(
      strategy.parameters._stableToken,
      strategy.parameters._investToken
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
    }

    if (
      strategy.parameters._highSellValue != 0 &&
      price > strategy.parameters._highSellValue
    ) {
      revert();
    }

    // Calculate the time interval for TWAP execution and check if it can be executed.
    uint256 timeToExecute = LibTime.convertToSeconds(
      strategy.parameters._sellTwapTime,
      strategy.parameters._sellTwapTimeUnit
    );
    bool canExecute = LibTime.getTimeDifference(
      block.timestamp,
      strategy.sellTwapExecutedAt,
      timeToExecute
    );

    if (!canExecute) {
      revert();
    }

    // Update the TWAP execution timestamp and perform the TWAP sell action.
    strategy.sellTwapExecutedAt = block.timestamp;
    transferSell(
      strategy,
      value,
      dex,
      callData,
      price,
      roundId,
      strategy.sellAt
    );

    // Mark the strategy as completed if there are no further buy actions and no assets left to invest.
    if (!strategy.parameters._buy && strategy.parameters._investAmount == 0) {
      strategy.status = Status.COMPLETED;
    }
    emit SellTwapExecuted(strategyId, dex, callData, price, block.timestamp);
  }

  /**
   * @notice Execute a strategy based on Spike Trigger (STR) conditions for a trading strategy.
   * @dev This function performs actions based on the specified strategy parameters and market conditions to execute Sell The Rally (STR) events.
   *      It verifies whether the strategy's parameters meet the required conditions for executing STR events.
   * @param strategyId The unique ID of the strategy to execute the STR actions for.
   * @param dex The address of the DEX (Decentralized Exchange) to use for the STR actions.
   * @param callData The calldata for interacting with the DEX.
   * @param fromRoundId The starting round ID for price data.
   * @param toRoundId The ending round ID for price data.
   */
  function executeSTR(
    uint256 strategyId,
    address dex,
    bytes calldata callData,
    uint80 fromRoundId,
    uint80 toRoundId
  ) public {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Ensure that STR events are selected in the strategy parameters.
    if (!strategy.parameters._str) {
      revert();
    }

    // Ensure that there is invest token available for selling.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // Retrieve the latest price and round ID from Chainlink.
    (uint256 price, uint80 roundId) = LibPrice.getPrice(
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
    checkRoundDataMistmatch(strategy, fromRoundId, toRoundId);
    // uint256 botPrice=LibPrice.getRoundData(botRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
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

    if (strategy.strLastTrackedPrice == 0) {
      if (price >= strategy.sellAt && price < highSellValue) {
        transferSell(strategy, value, dex, callData, price, roundId, sellValue);
        strategy.strLastTrackedPrice = price;
      }
    } else {
      if (
        strategy.parameters._strType == DIP_SPIKE.DECREASE_BY ||
        strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE
      ) {
        if (strategy.strLastTrackedPrice > price) {
          strategy.strLastTrackedPrice = price;
        } else if (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY) {
          uint256 sellPercentage = 100 - strategy.parameters._strValue;
          uint256 priceToSTR = (sellPercentage * strategy.strLastTrackedPrice) /
            100;
          if (priceToSTR <= price) {
            transferSell(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
              sellValue
            );
            strategy.strLastTrackedPrice = price;
          }
        } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
          uint256 priceToSTR = strategy.strLastTrackedPrice -
            strategy.parameters._strValue;
          if (priceToSTR <= price) {
            transferSell(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
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
          uint256 sellPercentage = 100 + strategy.parameters._strValue;
          uint256 priceToSTR = (sellPercentage * strategy.strLastTrackedPrice) /
            100;
          if (price > highSellValue) {
            strategy.strLastTrackedPrice = price;
          } else if (priceToSTR >= price) {
            transferSell(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
              sellValue
            );
            strategy.strLastTrackedPrice = price;
          }
        } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
          uint256 priceToSTR = strategy.strLastTrackedPrice +
            strategy.parameters._strValue;

          if (price > highSellValue) {
            strategy.strLastTrackedPrice = price;
          } else if (priceToSTR >= strategy.strLastTrackedPrice) {
            transferSell(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
              sellValue
            );
            strategy.strLastTrackedPrice = price;
          }
        }
      }
    }
    // Mark the strategy as completed if there are no further buy actions and no assets left to invest.

    if (!strategy.parameters._buy && strategy.parameters._investAmount == 0) {
      strategy.status = Status.COMPLETED;
    }
    emit STRExecuted(strategyId, dex, callData, price, block.timestamp);
  }

  /**
   * @notice Transfer assets from the trading strategy during a sell action.
   * @dev This function swaps a specified amount of assets on a DEX (Decentralized Exchange) and updates the strategy's state accordingly.
   * @param strategy The strategy being executed.
   * @param value The amount to be sold on the DEX.
   * @param dex The address of the DEX to use for the swap.
   * @param callData The calldata for interacting with the DEX.
   * @param price The current market price of the investment token.
   * @param roundId The round ID for price data.
   * @param sellValue The value at which the sell action was executed.
   */
  function transferSell(
    Strategy memory strategy,
    uint256 value,
    address dex,
    bytes calldata callData,
    uint256 price,
    uint80 roundId,
    uint256 sellValue
  ) internal {
    // Create a swap data structure for the DEX trade.
    LibSwap.SwapData memory swap = LibSwap.SwapData(
      dex,
      strategy.parameters._investToken,
      strategy.parameters._stableToken,
      value,
      callData,
      strategy.user
    );

    // Perform the asset swap on the DEX and calculate the exchange rate.
    uint256 toTokenAmount = LibSwap.swap(swap);

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
    if (!strategy.parameters._str) {
      LibTrade.validateSlippage(
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

    uint256 totalInvestAmount = strategy.parameters._investAmount *
      strategy.investPrice;
    uint256 sum = strategy.parameters._stableAmount + totalInvestAmount;

    if (strategy.budget < sum) {
      strategy.parameters._stableAmount = strategy.budget - totalInvestAmount;

      if (strategy.profit == 0) {
        strategy.profit = 0;
      }

      strategy.profit = sum - strategy.budget + strategy.profit;
    }

    // Update the strategy's timestamp, buy percentage amount, and round ID if necessary.

    strategy.timestamp = block.timestamp;
    strategy.parameters._investAmount -= value;
    strategy.parameters._stableAmount += toTokenAmount;
    strategy.roundId = roundId;
    // Calculate the buy percentage amount if buy actions are based on TWAP or BTD.
    if (
      (strategy.parameters._buyTwap || strategy.parameters._btd) &&
      strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE
    ) {
      strategy.buyPercentageAmount =
        (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) /
        100;
    }
  }

  function checkRoundDataMistmatch(
    Strategy memory strategy,
    uint80 fromRoundId,
    uint80 toRoundId
  ) internal view {
    if (
      fromRoundId == 0 || toRoundId == 0 || strategy.strLastTrackedPrice == 0
    ) {
      return;
    }

    uint8 decimals = IERC20Metadata(strategy.parameters._stableToken)
    .decimals();
    int256 priceDecimals = int256(100 * (10**uint256(decimals)));
    uint256 fromPrice = LibPrice.getRoundData(
      fromRoundId,
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );
    uint256 toPrice = LibPrice.getRoundData(
      toRoundId,
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
