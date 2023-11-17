// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error NoSwapFromZeroBalance();
error InsufficientBalance(uint256 required, uint256 balance);
error SwapFailed();
error TransferFailed();
error InvalidExchangeRate(uint256 required, uint256 actual);
error InvalidPrice();
error InvalidImpact();
error HighImpact();
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
error StrWithoutStrType();
error BTDWithoutBTDType();
error BuyDCAWithoutBuyDCAUnit();
error BuyDCAUnitWithoutBuyDCAValue();
error InvalidHighSellValue();
error SellDCAValueRangeIsNotValid();
error DCAValueShouldBeLessThanIntitialAmount();
error BuyDCAValueRangeIsNotValid();
error OrphandStrategy();
error BuyNeverExecute();
error FloorGreaterThanPrice();
error FeedNotFound();
error WrongPreviousIDs();
error RoundDataDoesNotMatch();
error StrategyIsNotActive();
error InvalidNonce();
error InvalidSigner();
error AlreadyCancelled();
error BuyNotSet();
error SellNotSelected();
error PercentageNotInRange();
error BuyTwapNotSelected();
error SellTwapNotSelected();
error FloorNotSet();
