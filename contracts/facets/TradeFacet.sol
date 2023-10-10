// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate } from "../utils/GenericErrors.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TradeFacet {
    AppStorage internal s;

    function executeBuy(uint256 strategyId, address dex, bytes calldata callData) external {
        Strategy storage strategy = s.strategies[strategyId];

        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.stableToken,
            strategy.investToken,
            strategy.amount,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = calculateExchangeRate(strategy.investToken, toTokenAmount, strategy.amount);

        if (rate > strategy.buyAt) {
            revert InvalidExchangeRate(
                strategy.buyAt,
                rate
            );
        }

        //   now compare with chainlink
    }

    /**
    @dev Calculate exchange rate given exchange amount
    @param fromAsset Address of the asset that was used to swap
    @param fromAmount Amount of the asset that was used to swap
    @param toAmount Amount of the asset that was received from swap
    @return uint256 Returns the exchange rate in toAsset unit
     */
    function calculateExchangeRate(
        address fromAsset,
        uint256 fromAmount,
        uint256 toAmount
    ) public view returns (uint256) {
        IERC20Metadata _fromToken = IERC20Metadata(fromAsset);
        uint256 fromDecimals = _fromToken.decimals();
        return (toAmount * (10 ** fromDecimals) / fromAmount); 
    }
}