// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage, Strategy, Status, Swap, FloorLegType } from "../AppStorage.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTrade } from "../libraries/LibTrade.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, StrategyIsNotActive } from "../utils/GenericErrors.sol";
error FloorNotSet();
error PriceIsGreaterThanFloorValue();

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
   * @param floorValue The value at which the floor action was executed.
   * @param slippage The allowable price slippage percentage for the buy action.
   * @param amount The amount of tokens bought.
   * @param exchangeRate The exchange rate at which the tokens were acquired.
   */
  event FloorExecuted(
    uint256 indexed strategyId,
    uint256 floorValue,
    uint256 slippage,
    uint256 amount,
    uint256 exchangeRate
  );

  /**
   * @notice Execute a floor price check and potential liquidation for a trading strategy.
   * @dev This function performs a floor price check and, if the strategy's parameters meet the required conditions,
   *      it may execute a liquidation of assets. Liquidation occurs if the strategy's floor price is reached and
   *      liquidation is enabled in the strategy parameters.
   * @param strategyId The unique ID of the strategy to execute the floor check for.
   * @param dexSwap The Swap struct containing address of the decentralized exchange (DEX) and calldata containing data for interacting with the DEX during the execution.
   */
  function executeFloor(uint256 strategyId, Swap calldata dexSwap) external {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];
    if (strategy.status != Status.ACTIVE) {
      revert StrategyIsNotActive();
    }

    // Check if the floor price is set in the strategy parameters.
    if (!strategy.parameters._floor) {
      revert FloorNotSet();
    }

    // Ensure that there are assets available for swapping.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
    .getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    uint256 floorAt;
    if (strategy.parameters._floorType == FloorLegType.LIMIT_PRICE) {
      floorAt = strategy.parameters._floorValue;
    } else if (strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
      uint256 floorPercentage = LibTrade.MAX_PERCENTAGE -
        strategy.parameters._floorValue;
      floorAt =
        (strategy.investPrice * floorPercentage) /
        LibTrade.MAX_PERCENTAGE;
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

      // Validate the slippage based on the calculated rate and the latest price.
      uint256 slippage = LibTrade.validateSlippage(
        rate,
        price,
        strategy.parameters._slippage,
        false
      );

      // Update strategy details, including timestamp, asset amounts, round ID, and invest price.
      strategy.parameters._investAmount = 0;
      strategy.parameters._stableAmount += toTokenAmount;
      strategy.investRoundId = investRoundId;
      strategy.stableRoundId = stableRoundId;
      strategy.investPrice = 0;

      // Check if the strategy should be canceled on reaching the floor price.
      if (strategy.parameters._cancelOnFloor) {
        strategy.status = Status.CANCELLED;
      }
      emit FloorExecuted(strategyId, price, slippage, toTokenAmount, rate);
    }
  }
}
