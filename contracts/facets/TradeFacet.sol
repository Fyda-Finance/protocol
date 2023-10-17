// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE  } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { InvalidExchangeRate, HighSlippage, NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
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

        if (rate > strategy.buyAt) {
            revert InvalidExchangeRate(
                strategy.buyAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if(strategy.parameters._floor&&strategy.floorAt>price){
            revert();
        }
        validateSlippage(rate, price, strategy.parameters._slippage, true);
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount+=toTokenAmount;
        strategy.parameters._stableAmount=0;
        strategy.investPrice=price;
        strategy.roundId=roundId;

        if ((strategy.parameters._sellTwap||strategy.parameters._str) && strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            strategy.sellPercentageAmount = (strategy.parameters._sellDCAValue * strategy.parameters._investAmount) / 100;
        }
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

        if (rate > strategy.floorAt) {
            revert InvalidExchangeRate(
                strategy.floorAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        validateSlippage(rate, price, strategy.parameters._slippage, false);
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount=0;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
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
        if(strategy.parameters._investAmount==0){
            revert NoSwapFromZeroBalance();
        }
      

        if(strategy.parameters._highSellValue!=0){
           if(strategy.sellAt>strategy.parameters._highSellValue){
            revert();
           }
        }
         else if(strategy.parameters._str||strategy.parameters._sellTwap){
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

        if(strategy.parameters._highSellValue!=0){
            if (rate < strategy.parameters._highSellValue){
                revert InvalidExchangeRate(
                strategy.parameters._highSellValue,
                rate
            );
            }
        }
        else if (rate < strategy.sellAt) {
            revert InvalidExchangeRate(
                strategy.sellAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount=0;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
        if ((strategy.parameters._buyTwap||strategy.parameters._btd) && strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
         strategy.buyPercentageAmount = (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) / 100;
     }
        validateSlippage(rate, price, strategy.parameters._slippage, false);
        if (!strategy.parameters._buy) {
             strategy.status = Status.COMPLETED;
        }
        
    }

    function executeBuyTwap(uint256 strategyId, address dex, bytes calldata callData) external{
        Strategy storage strategy = s.strategies[strategyId];
         if(!strategy.parameters._buyTwap){
            revert();
        }
        if(strategy.parameters._stableAmount==0){
            revert NoSwapFromZeroBalance();
        }

        uint256 timeToExecute=LibTime.convertToSeconds(strategy.parameters._buyTwapTime,strategy.parameters._buyTwapTimeUnit);
        bool canExecute=LibTime.getTimeDifference(block.timestamp,strategy.buyTwapExecutedAt,timeToExecute);
        if(!canExecute){
            revert();
        }

        uint256 value=0;
        if(strategy.parameters._buyDCAUnit==DCA_UNIT.FIXED){
           if(strategy.parameters._stableAmount>strategy.parameters._buyValue){
            value=strategy.parameters._buyValue;
           }
           else{
            value=strategy.parameters._stableAmount;
           }
        }
        else if(strategy.parameters._buyDCAUnit==DCA_UNIT.PERCENTAGE){
            value=strategy.buyPercentageAmount;
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

        uint256 rate = calculateExchangeRate(strategy.parameters._investToken, toTokenAmount, value);

        if (rate > strategy.buyAt) {
            revert InvalidExchangeRate(
                strategy.buyAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if(strategy.parameters._floor&&strategy.floorAt>price){
            revert();
        }
        validateSlippage(rate, price, strategy.parameters._slippage, true);
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount+=toTokenAmount;
        strategy.parameters._stableAmount-=value;
        strategy.investPrice=price;
        strategy.roundId=roundId;
        strategy.buyTwapExecutedAt=block.timestamp;
        if ((strategy.parameters._sellTwap||strategy.parameters._str) && strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            strategy.sellPercentageAmount = (strategy.parameters._sellDCAValue * strategy.parameters._investAmount) / 100;
        }
        if (!strategy.parameters._sell && !strategy.parameters._floor&&strategy.parameters._stableAmount==0) {
             strategy.status = Status.COMPLETED;
        }
      
}

    
    function executeSellTwap(uint256 strategyId, address dex, bytes calldata callData) external{
        Strategy storage strategy = s.strategies[strategyId];
        if(!strategy.parameters._sellTwap){
                revert();
            }
        if(strategy.parameters._investAmount==0){
               revert NoSwapFromZeroBalance();
            }

        uint256 timeToExecute=LibTime.convertToSeconds(strategy.parameters._sellTwapTime,strategy.parameters._sellTwapTimeUnit);
        bool canExecute=LibTime.getTimeDifference(block.timestamp,strategy.sellTwapExecutedAt,timeToExecute);
        if(!canExecute){
            revert();
        }


        uint256 value=0;
        if(strategy.parameters._sellDCAUnit==DCA_UNIT.FIXED){
           if(strategy.parameters._investAmount>strategy.parameters._sellValue){
            value=strategy.parameters._sellValue;
           }
           else{
            value=strategy.parameters._investAmount;
           }
        }
        else if(strategy.parameters._sellDCAUnit==DCA_UNIT.PERCENTAGE){
            value=strategy.sellPercentageAmount;
        }

        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            value,
            callData,
            strategy.user
        );

       uint256 toTokenAmount = LibSwap.swap(swap);

       uint256 rate = calculateExchangeRate(strategy.parameters._investToken, value, toTokenAmount);

        if (rate < strategy.sellAt) {
            revert InvalidExchangeRate(
                strategy.sellAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._stableToken, strategy.parameters._investToken);
        validateSlippage(rate, price, strategy.parameters._slippage, false);
        strategy.sellTwapExecutedAt=block.timestamp;
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount-=value;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
        if ((strategy.parameters._buyTwap||strategy.parameters._btd) && strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
         strategy.buyPercentageAmount = (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) / 100;
     }
        if(!strategy.parameters._buy&&strategy.parameters._investAmount==0){
            strategy.status=Status.COMPLETED;
        }
    }

    function executeBTD(uint256 strategyId, address dex, bytes calldata callData,uint80 botRoundId) external{
        Strategy storage strategy = s.strategies[strategyId];
         if(!strategy.parameters._btd){
            revert();
        }
        if(strategy.parameters._stableAmount==0){
            revert NoSwapFromZeroBalance();
        }
        uint256 botPrice=LibPrice.getRoundData(botRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
        (uint256 price,uint80 roundId) = LibPrice.getPrice( strategy.parameters._investToken,strategy.parameters._stableToken);
        if(botPrice>price){
            revert();
        }
        
        uint256 value=0;
        if(strategy.parameters._buyDCAUnit==DCA_UNIT.FIXED){
           if(strategy.parameters._stableAmount>strategy.parameters._buyValue){
            value=strategy.parameters._buyValue;
           }
           else{
            value=strategy.parameters._stableAmount;
           }
        }
        else if(strategy.parameters._buyDCAUnit==DCA_UNIT.PERCENTAGE){
            value=strategy.buyPercentageAmount;
        }
        if(strategy.btdLastTrackedPrice==0){
            if(price<strategy.buyAt){
                transferBTD(strategy, value, dex, callData, price, roundId);
            }
    }
        else{

            if (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY ||strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) {
          if (strategy.btdLastTrackedPrice>price)
           {
             strategy.btdLastTrackedPrice = price;
          } else if (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY) {
            uint256 buyPercentage = 100-strategy.parameters._btdValue;
            uint256 priceToBTD = (buyPercentage*strategy.btdLastTrackedPrice)/100;
            if (priceToBTD<=price) {
            transferBTD(strategy,value,dex,callData,price,roundId);
            }
          } else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE) {
            uint256 priceToBTD = strategy.btdLastTrackedPrice-strategy.parameters._btdValue;
            if (priceToBTD<=price) {
              transferBTD(strategy,value,dex,callData,price,roundId);
            }
          }
        } else if ( strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY || strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) {
          if (strategy.btdLastTrackedPrice<price)
           {
            strategy.btdLastTrackedPrice = price;
          } else if (strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY) {
            uint256 buyPercentage = 100+strategy.parameters._btdValue; 
            uint256 priceToBTD = (buyPercentage*strategy.strLastTrackedPrice)/100;
            if (price>strategy.buyAt) {
              strategy.btdLastTrackedPrice = price;
            } else if (priceToBTD>=price) 
            {
                transferBTD(strategy,value,dex,callData,price,roundId);
            } 
          }
            else if (strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE) {
            uint256 priceToBTD = strategy.btdLastTrackedPrice+strategy.parameters._btdValue;
            
            if (price>strategy.buyAt) {
              strategy.btdLastTrackedPrice = price;
            } else if (priceToBTD>=strategy.btdLastTrackedPrice) {
             transferBTD(strategy,value,dex,callData,price,roundId);
}
          }
        }

        }
     

    }

    function executeSTR(uint256 strategyId, address dex, bytes calldata callData,uint80 botRoundId) public{
        Strategy storage strategy = s.strategies[strategyId];
        
        if(!strategy.parameters._str){
                revert();
        }
        if(strategy.parameters._investAmount==0){
               revert NoSwapFromZeroBalance();
        }
         
        uint256 highSellValue=strategy.parameters._highSellValue;
        if(strategy.parameters._highSellValue==0){
            highSellValue = type(uint).max;
        }
        uint256 botPrice=LibPrice.getRoundData(botRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken,strategy.parameters._stableToken);
        if(botPrice<price){
            revert();
        }
        
        uint256 value=0;
        if(strategy.parameters._sellDCAUnit==DCA_UNIT.FIXED){
           if(strategy.parameters._investAmount>strategy.parameters._sellValue){
            value=strategy.parameters._sellValue;
           }
           else{
            value=strategy.parameters._investAmount;
           }
        }
        else if(strategy.parameters._sellDCAUnit==DCA_UNIT.PERCENTAGE){
            value=strategy.sellPercentageAmount;
        }
        
        if(strategy.strLastTrackedPrice==0){
          if(price>=strategy.sellAt&&price<highSellValue){
            transferSTR(strategy,value,dex,callData,price,roundId);
          }  
       }
        else{
        if (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY ||strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
          if (strategy.strLastTrackedPrice>price)
           {
             strategy.strLastTrackedPrice = price;
          } else if (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY) {
            uint256 sellPercentage = 100-strategy.parameters._strValue;
            uint256 priceToSTR = (sellPercentage*strategy.strLastTrackedPrice)/100;
            if (priceToSTR<=price) {
            transferSTR(strategy,value,dex,callData,price,roundId);
            }
          } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
            uint256 priceToSTR = strategy.strLastTrackedPrice-strategy.parameters._strValue;
            if (priceToSTR<=price) {
              transferSTR(strategy,value,dex,callData,price,roundId);
            }
          }
        } else if ( strategy.parameters._strType == DIP_SPIKE.INCREASE_BY || strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
          if (strategy.strLastTrackedPrice<price)
           {
            strategy.strLastTrackedPrice = price;
          } else if (strategy.parameters._strType == DIP_SPIKE.INCREASE_BY) {
            uint256 sellPercentage = 100+strategy.parameters._strValue; 
            uint256 priceToSTR = (sellPercentage*strategy.strLastTrackedPrice)/100;
            if (price>highSellValue) {
              strategy.strLastTrackedPrice = price;
            } else if (priceToSTR>=price) 
            {
                transferSTR(strategy,value,dex,callData,price,roundId);
            } 
          }
            else if (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
            uint256 priceToSTR = strategy.strLastTrackedPrice+strategy.parameters._strValue;
            
            if (price>highSellValue) {
              strategy.strLastTrackedPrice = price;
            } else if (priceToSTR>=strategy.strLastTrackedPrice) {
             transferSTR(strategy,value,dex,callData,price,roundId);
}
          }
        }
  }
    }

    function transferSTR(Strategy memory strategy,uint256 value,address dex, bytes calldata callData, uint256 price,uint80 roundId) internal{
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            value,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = calculateExchangeRate(strategy.parameters._investToken, value, toTokenAmount);

        if (rate < strategy.strLastTrackedPrice) {
            revert InvalidExchangeRate(
                strategy.strLastTrackedPrice,
                rate
            );
        }
        strategy.strLastTrackedPrice=price;
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount-=value;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
        if ((strategy.parameters._buyTwap||strategy.parameters._btd) && strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
         strategy.buyPercentageAmount = (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) / 100;
     }
        if(!strategy.parameters._buy&&strategy.parameters._investAmount==0){
            strategy.status=Status.COMPLETED;
        }
    }

    function transferBTD(Strategy memory strategy,uint256 value,address dex, bytes calldata callData, uint256 price,uint80 roundId) internal{
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._stableToken,
            strategy.parameters._investToken,
            value,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = calculateExchangeRate(strategy.parameters._investToken, toTokenAmount, value);

        if (rate > strategy.btdLastTrackedPrice) {
            revert InvalidExchangeRate(
                strategy.btdLastTrackedPrice,
                rate
            );
        }
        strategy.btdLastTrackedPrice=price;
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount+=toTokenAmount;
        strategy.parameters._stableAmount-=value;
        strategy.roundId=roundId;
        if ((strategy.parameters._sellTwap||strategy.parameters._str) && strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
         strategy.sellPercentageAmount = (strategy.parameters._sellDCAValue * strategy.parameters._investAmount) / 100;
     }
        if(!strategy.parameters._sell&&!strategy.parameters._floor&&strategy.parameters._stableAmount==0){
            strategy.status=Status.COMPLETED;
        }
        validateSlippage(rate, price, strategy.parameters._slippage, true);

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