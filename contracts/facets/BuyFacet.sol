// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE, SellLegType, BuyLegType, FloorLegType, CURRENT_PRICE } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance, FloorGreaterThanPrice } from "../utils/GenericErrors.sol";
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

contract BuyFacet is Modifiers {
  AppStorage internal s;

  function executeBuy(
    uint256 strategyId,
    address dex,
    bytes calldata callData
  ) external {
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
    (uint256 price, uint80 roundId) = LibPrice.getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.NOT_SELECTED;
    }
    transferBuy(
      strategy,
      strategy.parameters._stableAmount,
      dex,
      callData,
      price,
      roundId,
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

  function executeBuyTwap(
    uint256 strategyId,
    address dex,
    bytes calldata callData
  ) external {
    Strategy storage strategy = s.strategies[strategyId];
    if (!strategy.parameters._buyTwap) {
      revert BuyTwapNotSelected();
    }
    if (strategy.parameters._stableAmount == 0) {
      revert NoSwapFromZeroBalance();
    }

    (uint256 price, uint80 roundId) = LibPrice.getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );
    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.NOT_SELECTED;
    }

    uint256 timeToExecute = LibTime.convertToSeconds(
      strategy.parameters._buyTwapTime,
      strategy.parameters._buyTwapTimeUnit
    );
    bool canExecute = LibTime.getTimeDifference(
      block.timestamp,
      strategy.buyTwapExecutedAt,
      timeToExecute
    );
    if (!canExecute) {
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
    transferBuy(strategy, value, dex, callData, price, roundId, strategy.buyAt);
    strategy.buyTwapExecutedAt = block.timestamp;
    if (
      !strategy.parameters._sell &&
      !strategy.parameters._floor &&
      strategy.parameters._stableAmount == 0
    ) {
      strategy.status = Status.COMPLETED;
    }

    strategy.totalBuyDCAInvestment = strategy.totalBuyDCAInvestment + value;

    uint256 prevInvestAmount = strategy.parameters._investAmount;
    strategy.parameters._investAmount =
      strategy.parameters._investAmount +
      value;

    uint256 prevInvestPrice = strategy.investPrice;

    uint256 previousValue = prevInvestAmount * prevInvestPrice;
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

  function executeBTD(
    uint256 strategyId,
    address dex,
    bytes calldata callData,
    uint80 fromRoundId,
    uint80 toRoundId
  ) external {
    Strategy storage strategy = s.strategies[strategyId];
    if (!strategy.parameters._btd) {
      revert BTDNotSelected();
    }
    if (strategy.parameters._stableAmount == 0) {
      revert NoSwapFromZeroBalance();
    }
    checkRoundDataMistmatch(strategy, fromRoundId, toRoundId);
    (uint256 price, uint80 roundId) = LibPrice.getPrice(
      strategy.parameters._investToken,
      strategy.parameters._stableToken
    );

    if (strategy.parameters.current_price == CURRENT_PRICE.BUY_CURRENT) {
      strategy.parameters._buyValue = price;
      strategy.buyAt = price;
      strategy.parameters._buyType = BuyLegType.LIMIT_PRICE;
      strategy.parameters.current_price = CURRENT_PRICE.NOT_SELECTED;
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
    }
    if (strategy.btdLastTrackedPrice == 0) {
      if (price < strategy.buyAt) {
        strategy.btdLastTrackedPrice = price;
        transferBuy(strategy, value, dex, callData, price, roundId, buyValue);
      }
    } else {
      if (
        strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY ||
        strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE
      ) {
        if (strategy.btdLastTrackedPrice > price) {
          strategy.btdLastTrackedPrice = price;
        } else if (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY) {
          uint256 buyPercentage = 100 - strategy.parameters._btdValue;
          uint256 priceToBTD = (buyPercentage * strategy.btdLastTrackedPrice) /
            100;
          if (priceToBTD <= price) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
              buyValue
            );
          }
        } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) {
          uint256 priceToBTD = strategy.btdLastTrackedPrice -
            strategy.parameters._btdValue;
          if (priceToBTD <= price) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
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
          uint256 buyPercentage = 100 + strategy.parameters._btdValue;
          uint256 priceToBTD = (buyPercentage * strategy.strLastTrackedPrice) /
            100;
          if (price > strategy.buyAt) {
            strategy.btdLastTrackedPrice = price;
          } else if (priceToBTD >= price) {
            transferBuy(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
              buyValue
            );
            strategy.btdLastTrackedPrice = price;
          }
        } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) {
          uint256 priceToBTD = strategy.btdLastTrackedPrice +
            strategy.parameters._btdValue;

          if (price > strategy.buyAt) {
            strategy.btdLastTrackedPrice = price;
          } else if (priceToBTD >= strategy.btdLastTrackedPrice) {
            strategy.btdLastTrackedPrice = price;
            transferBuy(
              strategy,
              value,
              dex,
              callData,
              price,
              roundId,
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

    uint256 prevInvestAmount = strategy.parameters._investAmount;
    strategy.parameters._investAmount =
      strategy.parameters._investAmount +
      value;

    uint256 prevInvestPrice = strategy.investPrice;

    uint256 previousValue = prevInvestAmount * prevInvestPrice;
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

  function transferBuy(
    Strategy memory strategy,
    uint256 value,
    address dex,
    bytes calldata callData,
    uint256 price,
    uint80 roundId,
    uint256 buyValue
  ) internal {
    if (
      strategy.parameters._floor &&
      strategy.floorAt > 0 &&
      strategy.floorAt > price
    ) {
      revert FloorGreaterThanPrice();
    }
    LibSwap.SwapData memory swap = LibSwap.SwapData(
      dex,
      strategy.parameters._stableToken,
      strategy.parameters._investToken,
      value,
      callData,
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
    strategy.timestamp = block.timestamp;
    strategy.parameters._investAmount += toTokenAmount;
    strategy.parameters._stableAmount -= value;
    strategy.roundId = roundId;
    if (
      (strategy.parameters._sellTwap || strategy.parameters._str) &&
      strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE
    ) {
      strategy.sellPercentageAmount =
        (strategy.parameters._sellDCAValue *
          strategy.parameters._investAmount) /
        100;
    }

    LibTrade.validateSlippage(rate, price, strategy.parameters._slippage, true);
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
