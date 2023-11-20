// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, BuyLegType, FloorLegType, CURRENT_PRICE, Swap } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, FloorGreaterThanPrice, WrongPreviousIDs, RoundDataDoesNotMatch, StrategyIsNotActive, BuyNotSet, BuyTwapNotSelected } from "../utils/GenericErrors.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import { LibTrade } from "../libraries/LibTrade.sol";

error BuyDCAIsSet();
error ExpectedTimeNotElapsed();
error BTDNotSelected();
error PriceIsGreaterThanBuyValue();
error PriceDippedBelowFloorValue();

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
     * @notice Emitted when a buy action is executed for a trading strategy.
     * @param strategyId The unique ID of the strategy where the buy action was executed.
     * @param impact The allowable price impact percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param investPrice the average price at which invest tokens were bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     */

    event BuyExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 investTokenAmount,
        uint256 investPrice,
        uint256 exchangeRate
    );

    /**
     * @notice Emitted when a Buy on Time-Weighted Average Price (TWAP) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
     * @param strategyId The unique ID of the strategy where the Buy on TWAP action was executed.
     * @param impact The allowable price impact percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param investPrice the average price at which invest tokens were bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     */
    event BuyTwapExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 investTokenAmount,
        uint256 investPrice,
        uint256 exchangeRate
    );
    /**
     * @notice Emitted when a Buy The Dip (BTD) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
     * @param strategyId The unique ID of the strategy where the BTD action was executed.
     * @param impact The allowable price impact percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param investPrice the average price at which invest tokens were bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     * @param investRoundId The invest round ID associated with the current price data.
     * @param stableRoundId The stable round ID associated with the current price data.
     */
    event BTDExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        uint256 investTokenAmount,
        uint256 investPrice,
        uint256 exchangeRate,
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
     * @notice Executes a buy action for a trading strategy based on specified conditions.
     * @dev The function validates strategy parameters, executes the buy action, and updates the strategy state.
     * @param strategyId The unique ID of the strategy for which the buy action is executed.
     * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
     */
    function executeBuy(uint256 strategyId, Swap calldata swap) external {
        Strategy storage strategy = s.strategies[strategyId];

        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        if (strategy.parameters._buyValue == 0) {
            revert BuyNotSet();
        }
        if (strategy.parameters._btdValue > 0 || strategy.parameters._buyTwapTime > 0) {
            revert BuyDCAIsSet();
        }
        if (strategy.parameters._stableAmount == 0) {
            revert NoSwapFromZeroBalance();
        }
        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 value = executionBuyAmount(true, strategyId);

        transferBuy(strategyId, value, swap, price, investRoundId, stableRoundId, strategy.parameters._buyValue);

        if (strategy.parameters._sellValue == 0 && strategy.parameters._floorValue == 0) {
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
        }
    }

    /**
     * @notice Executes a Buy on Time-Weighted Average Price (TWAP) action for a trading strategy.
     * @param strategyId The unique ID of the strategy to execute the Buy on TWAP action.
     * @param swap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
     */
    function executeBuyTwap(uint256 strategyId, Swap calldata swap) external {
        Strategy storage strategy = s.strategies[strategyId];

        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        if (strategy.parameters._buyTwapTime == 0) {
            revert BuyTwapNotSelected();
        }
        if (strategy.parameters._stableAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 timeToExecute = LibTime.convertToSeconds(
            strategy.parameters._buyTwapTime,
            strategy.parameters._buyTwapTimeUnit
        );

        bool execute = LibTime.getTimeDifference(block.timestamp, strategy.buyTwapExecutedAt, timeToExecute);

        if (!execute) {
            revert ExpectedTimeNotElapsed();
        }

        uint256 value = executionBuyAmount(false, strategyId);

        transferBuy(strategyId, value, swap, price, investRoundId, stableRoundId, strategy.parameters._buyValue);
        strategy.buyTwapExecutedAt = block.timestamp;
        if (
            strategy.parameters._sellValue == 0 &&
            strategy.parameters._floorValue == 0 &&
            strategy.parameters._stableAmount == 0
        ) {
            strategy.status = Status.COMPLETED;
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
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
        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        if (strategy.parameters._btdValue == 0) {
            revert BTDNotSelected();
        }
        if (strategy.parameters._stableAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        checkRoundPrices(
            strategyId,
            fromInvestRoundId,
            fromStableRoundId,
            toInvestRoundId,
            toStableRoundId,
            investRoundId,
            stableRoundId
        );

        uint256 value = executionBuyAmount(false, strategyId);

        transferBuy(strategyId, value, swap, price, investRoundId, stableRoundId, strategy.parameters._buyValue);
        if (
            strategy.parameters._sellValue == 0 &&
            strategy.parameters._floorValue == 0 &&
            strategy.parameters._stableAmount == 0
        ) {
            strategy.status = Status.COMPLETED;
            uint256 investPrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._investToken, investRoundId);
            uint256 stablePrice = LibPrice.getPriceBasedOnRoundId(strategy.parameters._stableToken, stableRoundId);
            emit StrategyCompleted(strategyId, investPrice, stablePrice);
        }
    }

    /**
     * @notice Calculate the effective value for a buy action in a trading strategy.
     * @param stableAmount Boolean flag indicating whether to consider the entire stable token amount.
     * @param strategyId The unique ID of the strategy for which to calculate the buy value.
     * @return The calculated buy value based on the specified parameters.
     */
    function executionBuyAmount(bool stableAmount, uint256 strategyId) public view returns (uint256) {
        uint256 amount;
        Strategy memory strategy = s.strategies[strategyId];
        if (stableAmount) {
            amount = strategy.parameters._stableAmount;
        } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) {
            amount = (strategy.parameters._stableAmount > strategy.parameters._buyDCAValue)
                ? strategy.parameters._buyDCAValue
                : strategy.parameters._stableAmount;
        } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
            uint256 buyPercentageAmount = (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) /
                LibTrade.MAX_PERCENTAGE;
            amount = (strategy.parameters._stableAmount > buyPercentageAmount)
                ? buyPercentageAmount
                : strategy.parameters._stableAmount;
        }

        return amount;
    }

    /**
     * @notice Internal function to execute a "Buy" action within a specified price range.
     * @dev This function transfers assets from stable tokens to investment tokens on a DEX.
     * @param strategyId The unique ID of the trading strategy where the BTD action is executed.
     * @param value The value to be transferred from stable tokens to investment tokens.
     * @param dexSwap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
     * @param price The current price of the investment token.
     * @param investRoundId The invest round ID associated with the current price data.
     * @param stableRoundId The stable round ID associated with the current price data.
     * @param buyValue The target price at which the "Buy" action should be executed.
     */

    function transferBuy(
        uint256 strategyId,
        uint256 value,
        Swap memory dexSwap,
        uint256 price,
        uint80 investRoundId,
        uint80 stableRoundId,
        uint256 buyValue
    ) internal {
        Strategy storage strategy = s.strategies[strategyId];
        if (price > buyValue) {
            revert PriceIsGreaterThanBuyValue();
        }

        if (strategy.parameters._floorValue > 0) {
            uint256 floorAt;
            if (strategy.parameters._floorType == FloorLegType.LIMIT_PRICE) {
                floorAt = strategy.parameters._floorValue;
            } else if (strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
                uint256 floorPercentage = LibTrade.MAX_PERCENTAGE - strategy.parameters._floorValue;
                floorAt = (strategy.investPrice * floorPercentage) / LibTrade.MAX_PERCENTAGE;
            }

            if (floorAt > price) {
                revert FloorGreaterThanPrice();
            }
        }
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dexSwap.dex,
            strategy.parameters._stableToken,
            strategy.parameters._investToken,
            value,
            dexSwap.callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = LibTrade.calculateExchangeRate(strategy.parameters._investToken, toTokenAmount, value);

        if (rate > buyValue) {
            revert InvalidExchangeRate(buyValue, rate);
        }

        strategy.parameters._stableAmount -= value;
        uint256 previousValue = strategy.parameters._investAmount * strategy.investPrice;
        strategy.parameters._investAmount = strategy.parameters._investAmount + toTokenAmount;

        strategy.investPrice = (previousValue + (toTokenAmount * price)) / strategy.parameters._investAmount;

        strategy.investRoundId = investRoundId;
        strategy.stableRoundId = stableRoundId;

        uint256 impact = LibTrade.validateImpact(rate, price, strategy.parameters._impact, true);

        if (
            strategy.parameters._buyValue > 0 &&
            strategy.parameters._btdValue == 0 &&
            strategy.parameters._buyTwapTime == 0
        ) {
            emit BuyExecuted(strategyId, impact, toTokenAmount, strategy.investPrice, rate);
        } else if (strategy.parameters._btdValue > 0) {
            emit BTDExecuted(
                strategyId,
                impact,
                toTokenAmount,
                strategy.investPrice,
                rate,
                strategy.investRoundId,
                strategy.stableRoundId
            );
        } else if (strategy.parameters._buyTwapTime > 0) {
            emit BuyTwapExecuted(strategyId, impact, toTokenAmount, strategy.investPrice, rate);
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

        uint256 btdValue = strategy.parameters._btdValue;
        uint256 fromToPriceDifference;
        uint256 toFromPriceDifference;

        if (
            (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE ||
                strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY)
        ) {
            if (toPrice < fromPrice) {
                revert RoundDataDoesNotMatch();
            } else {
                toFromPriceDifference = toPrice - fromPrice;
            }
        }
        if (
            (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE ||
                strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY)
        ) {
            if (toPrice > fromPrice) {
                revert RoundDataDoesNotMatch();
            } else {
                fromToPriceDifference = fromPrice - toPrice;
            }
        }

        if ((strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) && (btdValue > toFromPriceDifference)) {
            revert RoundDataDoesNotMatch();
        } else if ((strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) && (btdValue > fromToPriceDifference)) {
            revert RoundDataDoesNotMatch();
        } else if (
            (strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY) &&
            (btdValue > ((toFromPriceDifference * 10000) / fromPrice))
        ) {
            revert RoundDataDoesNotMatch();
        } else if (
            (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY) &&
            (btdValue > ((fromToPriceDifference * 10000) / fromPrice))
        ) {
            revert RoundDataDoesNotMatch();
        }
    }
}
