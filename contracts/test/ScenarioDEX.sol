// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ScenarioERC20} from "./ScenarioERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ScenarioDEX {
    // total decimals for USD price
    uint256 public constant USD_DECIMALS = 8;

    // asset => exchangeRate in USD
    mapping(address => uint256) public exchangeRate;

    function updateExchangeRate(address asset, uint256 rate) external {
        exchangeRate[asset] = rate;
    }

    function swap(
        address fromAsset,
        address toAsset,
        uint256 fromAmount
    ) external {
        require(
            exchangeRate[fromAsset] > 0,
            "ScenarioDEX: exchange rate not set"
        );
        require(
            exchangeRate[toAsset] > 0,
            "ScenarioDEX: exchange rate not set"
        );
        require(
            fromAmount > 0,
            "ScenarioDEX: fromAmount must be greater than 0"
        );

        IERC20Metadata _fromToken = IERC20Metadata(fromAsset);
        IERC20Metadata _toToken = IERC20Metadata(toAsset);

        uint256 fromAmountInUSD = (fromAmount * exchangeRate[fromAsset]) /
            (10**_fromToken.decimals());
        uint256 toAmount = (fromAmountInUSD * 10**_toToken.decimals()) /
            exchangeRate[toAsset];

        ScenarioERC20(toAsset).mint(address(this), toAmount);
        SafeERC20.safeTransfer(IERC20(toAsset), msg.sender, toAmount);
        SafeERC20.safeTransferFrom(IERC20(fromAsset), msg.sender, address(this), fromAmount);
    }
}
