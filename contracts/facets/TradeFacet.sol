// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, HighSlippage, NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import "hardhat/console.sol";


contract TradeFacet is Modifiers {
    AppStorage internal s;

    function executeBuy(uint256 strategyId, address dex, bytes calldata callData) external {
        
        Strategy storage strategy = s.strategies[strategyId];
        if(!strategy.parameters._buy){
            revert();
        }
        if(strategy.parameters._btd||strategy.parameters._buyTwap){
            revert();
        }
        if(strategy.parameters._stableAmount==0){
            revert NoSwapFromZeroBalance();
        }
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._stableToken,
            strategy.parameters._investToken,
            strategy.parameters._stableAmount,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = calculateExchangeRate(strategy.parameters._investToken, toTokenAmount, strategy.parameters._stableAmount);

        if (rate > strategy.parameters._buyAt) {
            revert InvalidExchangeRate(
                strategy.parameters._buyAt,
                rate
            );
        }

        //   now compare with chainlink
        uint256 price = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if(strategy.parameters._floor&&strategy.parameters._floorAt>price){
            revert();
        }
        validateSlippage(rate, price, strategy.parameters._slippage, true);
        if (!strategy.parameters._sell && !strategy.parameters._floor) {
             strategy.status = Status.COMPLETED;
        }
        
    }

    function executeFloor(uint256 strategyId, address dex, bytes calldata callData) external {
        Strategy storage strategy = s.strategies[strategyId];
         if(!strategy.parameters._floor){
            revert();
        }

         if(strategy.parameters._investAmount==0){
            revert NoSwapFromZeroBalance();
        }
      
        if(strategy.parameters._liquidateOnFloor){
            LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            strategy.parameters._investAmount,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

       uint256 rate = calculateExchangeRate(strategy.parameters._investToken, strategy.parameters._investAmount, toTokenAmount);

        if (rate > strategy.parameters._floorAt) {
            revert InvalidExchangeRate(
                strategy.parameters._floorAt,
                rate
            );
        }

        //   now compare with chainlink
        uint256 price = LibPrice.getPrice(strategy.parameters._stableToken, strategy.parameters._investToken);
        validateSlippage(rate, price, strategy.parameters._slippage, false);
        if(strategy.parameters._cancelOnFloor){
            strategy.status=Status.CANCELLED;
        }
}
        
    }

    function executeSell(uint256 strategyId, address dex, bytes calldata callData) external {
        Strategy storage strategy = s.strategies[strategyId];
         if(!strategy.parameters._sell){
            revert();
        }
        if(strategy.parameters._str||strategy.parameters._sellTwap){
            revert();
        }

        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            strategy.parameters._investAmount,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

       uint256 rate = calculateExchangeRate(strategy.parameters._investToken, strategy.parameters._investAmount, toTokenAmount);

        if (rate < strategy.parameters._sellAt) {
            revert InvalidExchangeRate(
                strategy.parameters._sellAt,
                rate
            );
        }

        //   now compare with chainlink
        uint256 price = LibPrice.getPrice(strategy.parameters._stableToken, strategy.parameters._investToken);
        validateSlippage(rate, price, strategy.parameters._slippage, false);
        if (!strategy.parameters._buy) {
             strategy.status = Status.COMPLETED;
        }
        
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