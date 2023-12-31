// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage, Strategy, Status, Swap, FloorLegType, TokensTransaction, DCA_UNIT } from "../AppStorage.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTrade } from "../libraries/LibTrade.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, StrategyIsNotActive, FloorNotSet } from "../utils/GenericErrors.sol";
error PriceIsGreaterThanFloorValue();
error MinimumLossRequired();

/**
 * @title RoundIds
 * @notice This struct stores round Id for the transaction of invest and stable tokens.
 * Struct Fields:
 * @param investRoundId: the round Id of the invest token.
 * @param stableRoundId: the round Id of the stable token
 */
struct RoundIds {
    uint80 investRoundId;
    uint80 stableRoundId;
}

/**
 * @title FloorFacet
 * @notice This facet contains functions responsible for evaluating conditions related to the floor price and liquidation events.
 * @dev FloorFacet specializes in verifying floor price conditions, handling liquidation actions when the floor price is reached,
 *      ensuring that the necessary criteria are met before taking any actions and also cancelling the strategy if provided.
 */

contract FloorFacet is Modifiers {
    /**
     * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
     * please look at AppStorage.sol for more detail
     */
    AppStorage internal s;

    /**
     * @notice Emitted when a floor execution is initiated for a trading strategy.
     * @param strategyId The unique ID of the strategy where the floor execution is initiated.
     * @param impact The allowable price impact percentage for the buy action.
     * @param tokens tokens substracted and added into the users wallet
     * @param stablePriceInUSD price of stable token in USD
     * @param investPrice the average price at which invest tokens were bought.
     * @param profit it is the profit made by the strategy.
     */
    event FloorExecuted(
        uint256 indexed strategyId,
        uint256 impact,
        TokensTransaction tokens,
        uint256 stablePriceInUSD,
        uint256 investPrice,
        uint256 profit
    );

    /**
     * @notice Emitted when a floor execution happens with BTD value.
     * @param strategyId The unique ID of the strategy where the floor execution is initiated.
     * @param rounds the round Ids of invest and stable tokens.
     */

    event ExecutedWithBTD(uint256 indexed strategyId, RoundIds rounds);
    /**
     * @notice Emitted when a trade execution strategy is cancelled.
     * @param strategyId The unique ID of the cancelled strategy.
     * @param investTokenPrice The price of the invest token in USD.
     * @param stableTokenPrice The price of the stable token in USD.
     */
    event StrategyCancelled(uint256 indexed strategyId, uint256 investTokenPrice, uint256 stableTokenPrice);

    /**
     * @notice Execute a floor price check and potential liquidation for a trading strategy.
     * @dev This function performs a floor price check and, if the strategy's parameters meet the required conditions,
     *      it may execute a liquidation of assets. Liquidation occurs if the strategy's floor price is reached and
     *      liquidation is enabled in the strategy parameters.
     * @param strategyId The unique ID of the strategy to execute the floor check for.
     * @param dexSwap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
     */
    function executeFloor(uint256 strategyId, Swap calldata dexSwap) external nonReentrant {
        // Retrieve the strategy details.
        Strategy storage strategy = s.strategies[strategyId];
        uint256 stablePrice = LibPrice.getUSDPrice(strategy.parameters._stableToken);
        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        // Check if the floor price is set in the strategy parameters.
        if (strategy.parameters._floorValue == 0) {
            revert FloorNotSet();
        }

        // Ensure that there are assets available for swapping.
        if (strategy.parameters._investAmount == 0) {
            revert NoSwapFromZeroBalance();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            strategy.parameters._investToken,
            strategy.parameters._stableToken
        );

        uint256 floorAt;
        if (strategy.parameters._floorType == FloorLegType.LIMIT_PRICE) {
            floorAt = strategy.parameters._floorValue;
        } else if (strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
            uint256 floorPercentage = LibTrade.MAX_PERCENTAGE - strategy.parameters._floorValue;
            floorAt = (strategy.investPrice * floorPercentage) / LibTrade.MAX_PERCENTAGE;
        }

        if (price > floorAt) {
            revert PriceIsGreaterThanFloorValue();
        }

        // If liquidation is enabled, initiate a swap of assets.
        if (strategy.parameters._liquidateOnFloor) {
            // Prepare swap data for the DEX.
            LibSwap.SwapData memory swap = LibSwap.SwapData(
                dexSwap.dex,
                strategy.parameters._investToken,
                strategy.parameters._stableToken,
                strategy.parameters._investAmount,
                dexSwap.callData,
                strategy.user
            );

            // Execute the asset swap and calculate the exchange rate.
            uint256 toTokenAmount = LibSwap.swap(swap);
            uint256 rate = LibTrade.calculateExchangeRate(
                strategy.parameters._investToken,
                strategy.parameters._investAmount,
                toTokenAmount
            );

            // Check if the calculated exchange rate is within the acceptable range.
            if (rate > floorAt) {
                revert InvalidExchangeRate(floorAt, rate);
            }

            if (strategy.parameters._floorType == FloorLegType.DECREASE_BY && strategy.parameters._minimumLoss > 0) {
                // Check for mimimum loss
                uint256 invested = (strategy.parameters._investAmount * strategy.investPrice) /
                    10 ** IERC20Metadata(strategy.parameters._investToken).decimals();
                uint256 sold = toTokenAmount;
                uint256 loss = invested - sold;

                if (loss < strategy.parameters._minimumLoss) {
                    revert MinimumLossRequired();
                }
            }

            // Validate the impact based on the calculated rate and the latest price.
            uint256 impact = LibTrade.validateImpact(rate, price, strategy.parameters._impact, false);

            // Update strategy details, including timestamp, asset amounts, round ID, and invest price.
            uint256 value = strategy.parameters._investAmount;
            strategy.parameters._investAmount = 0;
            strategy.investPrice = 0;
            uint256 remainingAmount = strategy.budget - strategy.parameters._stableAmount;

            if (toTokenAmount > remainingAmount) {
                strategy.parameters._stableAmount = strategy.parameters._stableAmount + remainingAmount;
                strategy.profit = toTokenAmount - remainingAmount + strategy.profit;
            } else {
                strategy.parameters._stableAmount = strategy.parameters._stableAmount + toTokenAmount;
            }

            if (strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
                strategy.buyPercentageAmount =
                    (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) /
                    LibTrade.MAX_PERCENTAGE;
                strategy.buyPercentageTotalAmount = strategy.parameters._stableAmount;
            }
            emitEvents(strategyId, impact, value, toTokenAmount, stablePrice, investRoundId, stableRoundId);
        }

        // Check if the strategy should be canceled on reaching the floor price.

        if (strategy.parameters._cancelOnFloor) {
            uint256 investPrice = LibPrice.getUSDPrice(strategy.parameters._investToken);
            strategy.status = Status.CANCELLED;
            emit StrategyCancelled(strategyId, investPrice, stablePrice);
        }

        if (strategy.parameters._cancelOnFloor == false && strategy.parameters._buyValue == 0) {
            strategy.status = Status.CANCELLED;
            emit StrategyCancelled(strategyId, 0, stablePrice);
        }
    }

    function emitEvents(
        uint256 strategyId,
        uint256 impact,
        uint256 value,
        uint256 toTokenAmount,
        uint256 stablePrice,
        uint80 investRoundId,
        uint80 stableRoundId
    ) internal {
        Strategy storage strategy = s.strategies[strategyId];

        emit FloorExecuted(
            strategyId,
            impact,
            TokensTransaction({
                tokenSubstracted: value,
                tokenAdded: toTokenAmount,
                stableAmount: strategy.parameters._stableAmount,
                investAmount: strategy.parameters._investAmount
            }),
            stablePrice,
            strategy.investPrice,
            strategy.profit
        );

        if (strategy.parameters._btdValue > 0 && strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
            strategy.investRoundIdForBTD = investRoundId;
            strategy.stableRoundIdForBTD = stableRoundId;
            emit ExecutedWithBTD(strategyId, RoundIds({ investRoundId: investRoundId, stableRoundId: stableRoundId }));
        }
    }
}
