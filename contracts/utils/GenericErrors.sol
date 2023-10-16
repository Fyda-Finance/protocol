// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error NoSwapFromZeroBalance();
error InsufficientBalance(uint256 required, uint256 balance);
error SwapFailed();
error TransferFailed();
error InvalidExchangeRate(uint256 required, uint256 actual);
error InvalidPrice();
error InvalidSlippage();
error HighSlippage();
error InvalidInvestToken();
error InvalidStableToken();
error TokensMustDiffer();
error AtLeastOneOptionRequired();
error InvalidInvestAmount();
error FloorValueZero();
error InvalidSellType();
error InvalidSellValue();
error BuyAndSellAtMisorder();
error InvalidStableAmount();
error InvalidBuyType();
error InvalidBuyValue();
error InvalidFloorValue();
error InvalidFloorType();
error InvalidSellTypeDCA();
error BuySellAndZeroAmount();
error FloorValueGreaterThanBuyValue();
error FloorValueGreaterThanSellValue();
error SellPercentageWithDCA();
error FloorPercentageWithDCA();
error BothBuyTwapAndBTD();
error BuyDCAWithoutBuy();
error BuyTwapTimeInvalid();
error BuyTwapTimeUnitNotSelected();
error BothSellTwapAndSTR();
error SellDCAWithoutSell();
error SellTwapTimeUnitNotSelected();
error SellTwapTimeInvalid();
error SellTwapOrStrWithoutSellDCAUnit();
error SellDCAUnitWithoutSellDCAValue();
error StrWithoutStrValueOrType();
error BTDWithoutBTDType();
error BTDTypeWithoutBTDValue();
error BuyDCAWithoutBuyDCAUnit();
error BuyDCAUnitWithoutBuyDCAValue();
error InvalidHighSellValue();
error SellDCAValueRangeIsNotValid();
error SellDCAValueGreaterThanInvestAmount();
error BuyDCAValueRangeIsNotValid();
error BuyDCAValueGreaterThanStableAmount();





