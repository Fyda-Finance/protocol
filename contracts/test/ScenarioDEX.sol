// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ScenarioERC20 } from "./ScenarioERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract ScenarioDEX {
    // total decimals for USD price
    uint256 public constant USD_DECIMALS = 8;

    uint256 public constant MAX_SLIPPAGE = 10000;

    // asset => exchangeRate in USD
    mapping(address => uint256) public exchangeRate;

    // asset => feed in USD
    mapping (address => address) public feeds;

    // MAX_SLIPPAGE = 100% = 10000
    uint256 public slippage = 0;

    function updateExchangeRate(address asset, uint256 rate) external {
        exchangeRate[asset] = rate;
    }

    function updateFeed(address asset, address feed) external {
        feeds[asset] = feed;
    }

    function updateSlippage(uint256 _slippage) external {
        require(_slippage <= MAX_SLIPPAGE, "ScenarioDEX: slippage must be less than 100%");
        slippage = _slippage;
    }

    function getPrice(address asset) public view returns (uint256) {
        require(feeds[asset] != address(0) || exchangeRate[asset] > 0, "ScenarioDEX: price not set");

        if (feeds[asset] != address(0)) {
            return uint256(AggregatorV2V3Interface(feeds[asset]).latestAnswer());
        } else {
            return exchangeRate[asset];
        }
    }

    function swap(
        address fromAsset,
        address toAsset,
        uint256 fromAmount
    ) external {
        require(fromAmount > 0, "ScenarioDEX: fromAmount must be greater than 0");

        IERC20Metadata _fromToken = IERC20Metadata(fromAsset);
        IERC20Metadata _toToken = IERC20Metadata(toAsset);

        uint256 fromAmountInUSD = (fromAmount * getPrice(fromAsset)) / (10**_fromToken.decimals());
        uint256 toAmount = (fromAmountInUSD * 10**_toToken.decimals()) /  getPrice(toAsset);

        uint256 slippageAmount = (toAmount * slippage) / MAX_SLIPPAGE;

        ScenarioERC20(toAsset).mint(address(this), toAmount - slippage);
        SafeERC20.safeTransfer(IERC20(toAsset), msg.sender, toAmount - slippage);
        SafeERC20.safeTransferFrom(IERC20(fromAsset), msg.sender, address(this), fromAmount);
    }
}