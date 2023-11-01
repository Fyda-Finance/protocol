// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {HighSlippage} from "../utils/GenericErrors.sol";
import "hardhat/console.sol";

library LibTrade {
    uint256 public constant MAX_PERCENTAGE = 10000;

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
    ) internal view returns (uint256) {
        IERC20Metadata _fromToken = IERC20Metadata(fromAsset);
        uint256 fromDecimals = _fromToken.decimals();
        return ((toAmount * (10**fromDecimals)) / fromAmount);
    }

    function validateSlippage(
        uint256 exchangeRate,
        uint256 price,
        uint256 maxSlippage,
        bool isBuy
    ) internal pure returns (uint256) {
        uint256 slippage = (price * MAX_PERCENTAGE) / exchangeRate;

        if (
            isBuy &&
            slippage < MAX_PERCENTAGE &&
            MAX_PERCENTAGE - slippage > maxSlippage
        ) revert HighSlippage();
        if (
            !isBuy &&
            slippage > MAX_PERCENTAGE &&
            slippage - MAX_PERCENTAGE > maxSlippage
        ) revert HighSlippage();
        console.log("Slippage %s", slippage);
        return slippage;
    }
}
