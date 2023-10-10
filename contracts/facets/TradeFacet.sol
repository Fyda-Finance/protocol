// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, HighSlippage } from "../utils/GenericErrors.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { LibPrice } from "../libraries/LibPrice.sol";

contract TradeFacet is Modifiers {
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
        uint256 price = LibPrice.getPrice(strategy.investToken, strategy.stableToken);
        validateSlippage(rate, price, strategy.slippage, true);
    }

    /**
    @dev Calculate exchange rate given input and output amounts
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

    /**
    @dev Set the chainlink feed registry address
    @param _chainlinkFeedRegistry Address of the chainlink feed registry
     */
    function setChainlinkFeedRegistry(address _chainlinkFeedRegistry) external onlyOwner {
        s.chainlinkFeedRegistry = _chainlinkFeedRegistry;
    }

    function validateSlippage(
        uint256 exchangeRate,
        uint256 price,
        uint256 maxSlippage,
        bool isBuy
    ) public pure {
        uint256 slippage = (price * MAX_PERCENTAGE) / exchangeRate;

        if (isBuy && slippage < MAX_PERCENTAGE && MAX_PERCENTAGE - slippage > maxSlippage) revert HighSlippage();
        if (!isBuy && slippage > MAX_PERCENTAGE && slippage - MAX_PERCENTAGE > maxSlippage) revert HighSlippage();
    }
}