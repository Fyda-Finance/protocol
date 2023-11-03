// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, BuyLegType, FloorLegType, CURRENT_PRICE, Swap} from "../AppStorage.sol";
import {LibSwap} from "../libraries/LibSwap.sol";
import {InvalidExchangeRate, NoSwapFromZeroBalance, FloorGreaterThanPrice, WrongPreviousIDs, RoundDataDoesNotMatch, StrategyIsNotActive} from "../utils/GenericErrors.sol";
import {Modifiers} from "../utils/Modifiers.sol";
import {LibPrice} from "../libraries/LibPrice.sol";
import {LibTime} from "../libraries/LibTime.sol";
import {LibTrade} from "../libraries/LibTrade.sol";

error BuyNotSet();
error BuyDCAIsSet();
error BuyTwapNotSelected();
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
     * @param price The price at which the buy action was executed.
     * @param slippage The allowable price slippage percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     */

    event BuyExecuted(
        uint256 indexed strategyId,
        uint256 price,
        uint256 slippage,
        uint256 investTokenAmount,
        uint256 exchangeRate
    );

    /**
     * @notice Emitted when a Buy on Time-Weighted Average Price (TWAP) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
     * @param strategyId The unique ID of the strategy where the Buy on TWAP action was executed.
     * @param price The price at which the Buy on TWAP action was executed.
     * @param slippage The allowable price slippage percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     * @param time The time at which it was executed.
     */
    event BuyTwapExecuted(
        uint256 indexed strategyId,
        uint256 price,
        uint256 slippage,
        uint256 investTokenAmount,
        uint256 exchangeRate,
        uint256 time
    );
    /**
     * @notice Emitted when a Buy The Dip (BTD) action is executed for a trading strategy using a specific DEX, call data, buy value, and execution time.
     * @param strategyId The unique ID of the strategy where the BTD action was executed.
     * @param price The price at which the BTD action was executed.
     * @param slippage The allowable price slippage percentage for the buy action.
     * @param investTokenAmount The amount of invest tokens bought.
     * @param exchangeRate The exchange rate at which the tokens were acquired.
     */
    event BTDExecuted(
        uint256 indexed strategyId,
        uint256 price,
        uint256 slippage,
        uint256 investTokenAmount,
        uint256 exchangeRate
    );

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

        updateCurrentPrice(strategyId, price);
        uint256 value = executionBuyAmount(true, strategyId);

        transferBuy(
            strategyId,
            value,
            swap,
            price,
            investRoundId,
            stableRoundId,
            strategy.parameters._buyValue
        );

        if (!strategy.parameters._sell && !strategy.parameters._floor) {
            strategy.status = Status.COMPLETED;
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

        updateCurrentPrice(strategyId, price);

        uint256 timeToExecute = LibTime.convertToSeconds(
            strategy.parameters._buyTwapTime,
            strategy.parameters._buyTwapTimeUnit
        );

        bool execute = LibTime.getTimeDifference(
            block.timestamp,
            strategy.buyTwapExecutedAt,
            timeToExecute
        );

        if (!execute) {
            revert ExpectedTimeNotElapsed();
        }

        uint256 value = executionBuyAmount(false, strategyId);

        transferBuy(
            strategyId,
            value,
            swap,
            price,
            investRoundId,
            stableRoundId,
            strategy.parameters._buyValue
        );
        strategy.buyTwapExecutedAt = block.timestamp;
        if (
            !strategy.parameters._sell &&
            !strategy.parameters._floor &&
            strategy.parameters._stableAmount == 0
        ) {
            strategy.status = Status.COMPLETED;
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

        if (!strategy.parameters._btd) {
            revert BTDNotSelected();
        }
        if (strategy.parameters._stableAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
        .getPrice(
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

        transferBuy(
            strategyId,
            value,
            swap,
            price,
            investRoundId,
            stableRoundId,
            strategy.parameters._buyValue
        );
        if (
            !strategy.parameters._sell &&
            !strategy.parameters._floor &&
            strategy.parameters._stableAmount == 0
        ) {
            strategy.status = Status.COMPLETED;
        }
    }

    /**
     * @notice Calculate the effective value for a buy action in a trading strategy.
     * @param stableAmount Boolean flag indicating whether to consider the entire stable token amount.
     * @param strategyId The unique ID of the strategy for which to calculate the buy value.
     * @return The calculated buy value based on the specified parameters.
     */
    function executionBuyAmount(bool stableAmount, uint256 strategyId)
        public
        view
        returns (uint256)
    {
        uint256 amount;
        Strategy memory strategy = s.strategies[strategyId];
        if (stableAmount) {
            amount = strategy.parameters._stableAmount;
        } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) {
            amount = (strategy.parameters._stableAmount >
                strategy.parameters._buyDCAValue)
                ? strategy.parameters._buyDCAValue
                : strategy.parameters._stableAmount;
        } else if (strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
            uint256 buyPercentageAmount = (strategy.parameters._buyDCAValue *
                strategy.parameters._stableAmount) / LibTrade.MAX_PERCENTAGE;
            amount = (strategy.parameters._stableAmount > buyPercentageAmount)
                ? buyPercentageAmount
                : strategy.parameters._stableAmount;
        }

        return amount;
    }

    /**
     * @notice Update the current price of a trading strategy based on the given price.
     * @param strategyId The unique ID of the strategy to update.
     * @param price The new price to set as the current price.
     */
    function updateCurrentPrice(uint256 strategyId, uint256 price) internal {
        Strategy storage strategy = s.strategies[strategyId];

        if (strategy.parameters._current_price == CURRENT_PRICE.BUY_CURRENT) {
            strategy.parameters._buyValue = price;
            strategy.parameters._current_price = CURRENT_PRICE.EXECUTED;
        }
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

        if (strategy.parameters._floor && strategy.parameters._floorValue > 0) {
            uint256 floorAt;
            if (strategy.parameters._floorType == FloorLegType.LIMIT_PRICE) {
                floorAt = strategy.parameters._floorValue;
            } else if (
                strategy.parameters._floorType == FloorLegType.DECREASE_BY
            ) {
                uint256 floorPercentage = LibTrade.MAX_PERCENTAGE -
                    strategy.parameters._floorValue;
                floorAt =
                    (strategy.investPrice * floorPercentage) /
                    LibTrade.MAX_PERCENTAGE;
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

        uint256 rate = LibTrade.calculateExchangeRate(
            strategy.parameters._investToken,
            toTokenAmount,
            value
        );

        if (rate > buyValue) {
            revert InvalidExchangeRate(buyValue, rate);
        }

        strategy.parameters._stableAmount -= value;
        uint256 previousValue = strategy.parameters._investAmount *
            strategy.investPrice;
        strategy.parameters._investAmount =
            strategy.parameters._investAmount +
            toTokenAmount;

        strategy.investPrice =
            (previousValue + (toTokenAmount * price)) /
            strategy.parameters._investAmount;

        strategy.investRoundId = investRoundId;
        strategy.stableRoundId = stableRoundId;

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
            emit BuyExecuted(strategyId, price, slippage, toTokenAmount, rate);
        } else if (strategy.parameters._btd) {
            emit BTDExecuted(strategyId, price, slippage, toTokenAmount, rate);
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

        if (
            presentInvestRound < toInvestRoundId ||
            presentStableRound < toStableRoundId
        ) {
            revert WrongPreviousIDs();
        }
        if (
            toInvestRoundId < fromInvestRoundId ||
            toStableRoundId < fromStableRoundId
        ) {
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

        if (
            (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) &&
            (btdValue > toFromPriceDifference)
        ) {
            revert RoundDataDoesNotMatch();
        } else if (
            (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) &&
            (btdValue > fromToPriceDifference)
        ) {
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
