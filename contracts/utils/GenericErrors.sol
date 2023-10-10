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