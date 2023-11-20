// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, CURRENT_PRICE, Swap } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, WrongPreviousIDs, RoundDataDoesNotMatch, StrategyIsNotActive, SellNotSelected, SellTwapNotSelected } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

error PriceLessThanHighSellValue();
error SellDCASelected();
error ValueGreaterThanHighSellValue();
error TWAPTimeDifferenceIsLess();
error STRNotSelected();
error PriceLessThanSellValue();
error PriceIsNotInTheRange();

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
     * @param impact The allowable price impact percentage for the buy action.
     * @param stableTokenAmount The amount of stable tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     * @param profit it is the profit made by the strategy.
     */
    event SellExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 stableTokenAmount,
        uint256 exchangeRate,
        uint256 profit
    );

    /**
     * @notice Emitted when a Time-Weighted Average Price (TWAP) sell action is executed for a trading strategy using a specific DEX and call data.
     * @param strategyId The unique ID of the strategy where the TWAP sell action was executed.
     * @param impact The allowable price impact percentage for the buy action.
     * @param stableTokenAmount The amount of stable tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     * @param profit it is the profit made by the strategy.
     */
    event SellTwapExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 stableTokenAmount,
        uint256 exchangeRate,
        uint256 profit
    );

    /**
     * @notice Emitted when a Spike Trigger (STR) event is executed for a trading strategy using a specific DEX and call data.
     * @param strategyId The unique ID of the strategy where the STR event was executed.
     * @param impact The allowable price impact percentage for the buy action.
     * @param stableTokenAmount The amount of stable tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     * @param profit it is the profit made by the strategy.
     * @param investRoundId The round ID for invest price data.
     * @param stableRoundId The round ID for stable price data.
     */
    event STRExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 stableTokenAmount,
        uint256 exchangeRate,
        uint256 profit,
        uint80 investRoundId,
        uint80 stableRoundId
    );

    /**
     * @notice Emitted when a trade execution strategy is completed.
     * @param strategyId The unique ID of the completed strategy.
     * @param investTokenPrice The price of the invest token in USD.
     * @param stableTokenPrice The price of the stable token in USD.
     */
    event StrategyCompleted(uint256 indexed strategyId, uint256 investTokenPrice, uint256 stableTokenPrice);

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

        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        // Ensure that selling is selected in the strategy parameters.
        if (strategy.parameters._sellValue == 0) {
            revert SellNotSelected();
        }

        // Ensure that there is invest token available for selling.
        if (strategy.parameters._investAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        // Retrieve the latest price and round ID from Chainlink.
        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 sellAt = strategy.parameters._sellValue;

        if (strategy.parameters._sellType == SellLegType.INCREASE_BY) {
            uint256 sellPercentage = LibTrade.MAX_PERCENTAGE + strategy.parameters._sellValue;
            sellAt = (strategy.investPrice * sellPercentage) / LibTrade.MAX_PERCENTAGE;
        }

        if (sellAt > price) {
            revert PriceLessThanSellValue();
        }

        if (strategy.parameters._highSellValue != 0) {
            // If a high sell value is specified and "strategy" or "sell TWAP" is selected, use the high sell value.
            sellAt = strategy.parameters._highSellValue;
            if (price < sellAt) {
                revert PriceLessThanHighSellValue();
            }
        } else if (strategy.parameters._strValue > 0 || strategy.parameters._sellTwapTime > 0) {
            // If neither high sell value nor "sell the rally" nor "sell TWAP" is selected, throw an error.
            revert SellDCASelected();
        }
        uint256 value = executionSellAmount(true, strategyId);

        // Perform the sell action, including transferring assets to the DEX.
        transferSell(strategyId, value, swap, price, investRoundId, stableRoundId, sellAt);

        // If there are no further buy actions in the strategy, mark it as completed.
        if (
            (strategy.parameters._buyValue == 0 || strategy.parameters._completeOnSell) &&
            strategy.parameters._investAmount == 0
        ) {
            // Retrieve the latest price and round ID from Chainlink.
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            strategy.status = Status.COMPLETED;
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
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

        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        // Ensure that TWAP sell is selected in the strategy parameters.
        if (strategy.parameters._sellTwapTime == 0) {
            revert SellTwapNotSelected();
        }

        // Ensure that there is invest token available for selling.
        if (strategy.parameters._investAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        // Retrieve the latest price and round ID from Chainlink.
        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 sellAt = strategy.parameters._sellValue;
        if (strategy.parameters._sellType == SellLegType.INCREASE_BY) {
            uint256 sellPercentage = LibTrade.MAX_PERCENTAGE + strategy.parameters._sellValue;
            sellAt = (strategy.investPrice * sellPercentage) / LibTrade.MAX_PERCENTAGE;
        }

        if (
            price < sellAt || (strategy.parameters._highSellValue != 0 && price >= strategy.parameters._highSellValue)
        ) {
            revert PriceIsNotInTheRange();
        }

        // Initialize value for the TWAP sell.
        uint256 value = executionSellAmount(false, strategyId);

        // Calculate the time interval for TWAP execution and check if it can be executed.
        uint256 timeToExecute = LibTime.convertToSeconds(
            strategy.parameters._sellTwapTime,
            strategy.parameters._sellTwapTimeUnit
        );
        bool execute = LibTime.getTimeDifference(block.timestamp, strategy.sellTwapExecutedAt, timeToExecute);

        if (!execute) {
            revert TWAPTimeDifferenceIsLess();
        }

        // Update the TWAP execution timestamp and perform the TWAP sell action.
        strategy.sellTwapExecutedAt = block.timestamp;
        transferSell(strategyId, value, swap, price, investRoundId, stableRoundId, sellAt);

        // Mark the strategy as completed if there are no further buy actions and no assets left to invest.
        if (
            (strategy.parameters._buyValue == 0 || strategy.parameters._completeOnSell) &&
            strategy.parameters._investAmount == 0
        ) {
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            strategy.status = Status.COMPLETED;
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
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
        uint80 fromInvestRoundId,
        uint80 fromStableRoundId,
        uint80 toInvestRoundId,
        uint80 toStableRoundId,
        Swap calldata swap
    ) public {
        // Retrieve the strategy details.
        Strategy storage strategy = s.strategies[strategyId];

        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        // Ensure that STR events are selected in the strategy parameters.
        if (strategy.parameters._strValue == 0) {
            revert STRNotSelected();
        }

        // Ensure that there is invest token available for selling.
        if (strategy.parameters._investAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        // Retrieve the latest price and round ID from Chainlink.
        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 sellAt = strategy.parameters._sellValue;
        if (strategy.parameters._sellType == SellLegType.INCREASE_BY) {
            uint256 sellPercentage = LibTrade.MAX_PERCENTAGE + strategy.parameters._sellValue;
            sellAt = (strategy.investPrice * sellPercentage) / LibTrade.MAX_PERCENTAGE;
        }

        if (
            price < sellAt || (strategy.parameters._highSellValue != 0 && price >= strategy.parameters._highSellValue)
        ) {
            revert PriceIsNotInTheRange();
        }

        checkRoundPrices(
            strategyId,
            fromInvestRoundId,
            fromStableRoundId,
            toInvestRoundId,
            toStableRoundId,
            investRoundId,
            stableRoundId
        );

        uint256 value = executionSellAmount(false, strategyId);

        transferSell(strategyId, value, swap, price, investRoundId, stableRoundId, sellAt);

        // Mark the strategy as completed if there are no further buy actions and no assets left to invest.

        if (
            (strategy.parameters._buyValue == 0 || strategy.parameters._completeOnSell) &&
            strategy.parameters._investAmount == 0
        ) {
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            strategy.status = Status.COMPLETED;
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
        }
    }

    /**
     * @notice Calculate the value to be sold in a trading strategy based on provided parameters.
     * @param investValue Boolean indicating whether the value is based on the investment amount.
     * @param strategyId The unique ID of the strategy for which the sell value is calculated.
     * @return The calculated value to be sold, which can be based on fixed or percentage units.
     */

    function executionSellAmount(bool investValue, uint256 strategyId) public view returns (uint256) {
        uint256 amount;
        Strategy memory strategy = s.strategies[strategyId];
        if (investValue) {
            amount = strategy.parameters._investAmount;
        } else if (strategy.parameters._sellDCAUnit == DCA_UNIT.FIXED) {
            amount = (strategy.parameters._investAmount > strategy.parameters._sellDCAValue)
                ? strategy.parameters._sellDCAValue
                : strategy.parameters._investAmount;
        } else if (strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            uint256 sellPercentageAmount = (strategy.parameters._sellDCAValue * strategy.parameters._investAmount) /
                LibTrade.MAX_PERCENTAGE;

            amount = (strategy.parameters._investAmount > sellPercentageAmount)
                ? sellPercentageAmount
                : strategy.parameters._investAmount;
        }
        return amount;
    }

    /**
     * @notice Transfer assets from the trading strategy during a sell action.
     * @dev This function swaps a specified amount of assets on a DEX (Decentralized Exchange) and updates the strategy's state accordingly.
     * @param strategyId The unique ID of the trading strategy where the BTD action is executed.
     * @param value The amount to be sold on the DEX.
     * @param dexSwap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
     * @param price The current market price of the investment token.
     * @param investRoundId The round ID for invest price data.
     * @param stableRoundId The round ID for stable price data.
     * @param sellValue The value at which the sell action was executed.
     */
    function transferSell(
        uint256 strategyId,
        uint256 value,
        Swap calldata dexSwap,
        uint256 price,
        uint80 investRoundId,
        uint80 stableRoundId,
        uint256 sellValue
    ) internal {
        Strategy storage strategy = s.strategies[strategyId];

        // Create a swap data structure for the DEX trade.
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dexSwap.dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            value,
            dexSwap.callData,
            strategy.user
        );

        // Perform the asset swap on the DEX and calculate the exchange rate.
        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = LibTrade.calculateExchangeRate(strategy.parameters._investToken, value, toTokenAmount);
        // Check if the exchange rate meets the specified sell value.
        if (rate < sellValue) {
            revert InvalidExchangeRate(sellValue, rate);
        }

        // Validate impact if the strategy is not an STR (Spike Trigger).
        uint256 impact = 0;
        if (
            strategy.parameters._strValue == 0 ||
            (strategy.parameters._highSellValue != 0 && price > strategy.parameters._highSellValue)
        ) {
            impact = LibTrade.validateImpact(rate, price, strategy.parameters._impact, false);
        }

        // Calculate the total investment amount and check if it exceeds the budget.

        uint256 decimals = 10 ** IERC20Metadata(strategy.parameters._investToken).decimals();

        strategy.parameters._investAmount = strategy.parameters._investAmount - value;
        strategy.parameters._stableAmount = strategy.parameters._stableAmount + toTokenAmount;

        uint256 totalInvestAmount = (strategy.parameters._investAmount * price) / decimals;
        uint256 sum = strategy.parameters._stableAmount + totalInvestAmount;

        if (strategy.budget < sum) {
            strategy.parameters._stableAmount = strategy.budget - totalInvestAmount;
            strategy.profit = sum - strategy.budget + strategy.profit;
        }

        // Update the strategy's timestamp, buy percentage amount, and round ID if necessary.

        strategy.investRoundId = investRoundId;
        strategy.stableRoundId = stableRoundId;
        // Calculate the buy percentage amount if buy actions are based on TWAP or BTD.

        if (
            (strategy.parameters._sellValue > 0 &&
                strategy.parameters._strValue == 0 &&
                strategy.parameters._sellTwapTime == 0) ||
            (strategy.parameters._sellValue > 0 && strategy.parameters._highSellValue > price)
        ) {
            emit SellExecuted(strategyId, impact, toTokenAmount, rate, strategy.profit);
        } else if (strategy.parameters._strValue > 0) {
            emit STRExecuted(
                strategyId,
                impact,
                toTokenAmount,
                rate,
                strategy.profit,
                strategy.investRoundId,
                strategy.stableRoundId
            );
        } else if (strategy.parameters._sellTwapTime > 0) {
            emit SellTwapExecuted(strategyId, impact, toTokenAmount, rate, strategy.profit);
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
     * @param presentInvestRound The present round ID for the invest token's price.
     * @param presentStableRound The present round ID for the stable token's price.
     */
    function checkRoundPrices(
        uint256 strategyId,
        uint80 fromInvestRoundId,
        uint80 fromStableRoundId,
        uint80 toInvestRoundId,
        uint80 toStableRoundId,
        uint80 presentInvestRound,
        uint80 presentStableRound
    ) internal view {
        Strategy memory strategy = s.strategies[strategyId];

        if (presentInvestRound < toInvestRoundId || presentStableRound < toStableRoundId) {
            revert WrongPreviousIDs();
        }
        if (toInvestRoundId < fromInvestRoundId || toStableRoundId < fromStableRoundId) {
            revert WrongPreviousIDs();
        }

        if (
            strategy.investRoundId >= fromInvestRoundId ||
            strategy.investRoundId >= toInvestRoundId ||
            strategy.stableRoundId >= fromStableRoundId ||
            strategy.stableRoundId >= toStableRoundId
        ) {
            revert WrongPreviousIDs();
        }

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

        uint256 strValue = strategy.parameters._strValue;
        uint256 fromToPriceDifference;
        uint256 toFromPriceDifference;

        if (
            (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE ||
                strategy.parameters._strType == DIP_SPIKE.INCREASE_BY)
        ) {
            if (toPrice < fromPrice) {
                revert RoundDataDoesNotMatch();
            } else {
                toFromPriceDifference = toPrice - fromPrice;
            }
        }
        if (
            (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE ||
                strategy.parameters._strType == DIP_SPIKE.DECREASE_BY)
        ) {
            if (toPrice > fromPrice) {
                revert RoundDataDoesNotMatch();
            } else {
                fromToPriceDifference = fromPrice - toPrice;
            }
        }

        if ((strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) && (strValue > toFromPriceDifference)) {
            revert RoundDataDoesNotMatch();
        } else if ((strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) && (strValue > fromToPriceDifference)) {
            revert RoundDataDoesNotMatch();
        } else if (
            (strategy.parameters._strType == DIP_SPIKE.INCREASE_BY) &&
            (strValue > ((toFromPriceDifference * 10000) / fromPrice))
        ) {
            revert RoundDataDoesNotMatch();
        } else if (
            (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY) &&
            (strValue > ((fromToPriceDifference * 10000) / fromPrice))
        ) {
            revert RoundDataDoesNotMatch();
        }
    }
}
