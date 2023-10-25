// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage, Strategy, Status } from "../AppStorage.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTrade } from "../libraries/LibTrade.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";

error FloorNotSet();

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
   * @param dex The address of the DEX used for the execution.
   * @param callData The calldata for interacting with the DEX.
   * @param floorValue The value at which the floor action was executed.
   * @param executedAt Timestamp when the floor action was executed.
   */
  event FloorExecuted(
    uint256 indexed strategyId,
    address dex,
    bytes callData,
    uint256 floorValue,
    uint256 executedAt
  );

  /**
   * @notice Execute a floor price check and potential liquidation for a trading strategy.
   * @dev This function performs a floor price check and, if the strategy's parameters meet the required conditions,
   *      it may execute a liquidation of assets. Liquidation occurs if the strategy's floor price is reached and
   *      liquidation is enabled in the strategy parameters.
   * @param strategyId The unique ID of the strategy to execute the floor check for.
   * @param dex The address of the DEX (Decentralized Exchange) to use for potential asset swaps.
   * @param callData The calldata for interacting with the DEX.
   */
  function executeFloor(
    uint256 strategyId,
    address dex,
    bytes calldata callData
  ) external {
    // Retrieve the strategy details.
    Strategy storage strategy = s.strategies[strategyId];

    // Check if the floor price is set in the strategy parameters.
    if (!strategy.parameters._floor) {
      revert FloorNotSet();
    }

    // Ensure that there are assets available for swapping.
    if (strategy.parameters._investAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    // If liquidation is enabled, initiate a swap of assets.
    if (strategy.parameters._liquidateOnFloor) {
      // Prepare swap data for the DEX.
      LibSwap.SwapData memory swap = LibSwap.SwapData(
        dex,
        strategy.parameters._investToken,
        strategy.parameters._stableToken,
        strategy.parameters._investAmount,
        callData,
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
      if (rate > strategy.floorAt) {
        revert InvalidExchangeRate(strategy.floorAt, rate);
      }

      // Retrieve the latest price and round ID from Chainlink.
      (uint256 price, uint80 roundId) = LibPrice.getPrice(
        strategy.parameters._investToken,
        strategy.parameters._stableToken
      );

      // Validate the slippage based on the calculated rate and the latest price.
      LibTrade.validateSlippage(
        rate,
        price,
        strategy.parameters._slippage,
        false
      );

      // Update strategy details, including timestamp, asset amounts, round ID, and invest price.
      strategy.timestamp = block.timestamp;
      strategy.parameters._investAmount = 0;
      strategy.parameters._stableAmount += toTokenAmount;
      strategy.roundId = roundId;
      strategy.investPrice = 0;

      // Check if the strategy should be canceled on reaching the floor price.
      if (strategy.parameters._cancelOnFloor) {
        strategy.status = Status.CANCELLED;
      }
      emit FloorExecuted(strategyId, dex, callData, price, block.timestamp);
    }
  }
}
