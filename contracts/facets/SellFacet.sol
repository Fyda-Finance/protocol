// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AppStorage, Strategy, Status, DCA_UNIT, DIP_SPIKE,SellLegType, CURRENT_PRICE  } from "../AppStorage.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidExchangeRate, NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTime } from "../libraries/LibTime.sol";
import {LibTrade} from "../libraries/LibTrade.sol";


contract SellFacet is Modifiers {
    AppStorage internal s;
    function executeSell(uint256 strategyId, address dex, bytes calldata callData) external {
        Strategy storage strategy = s.strategies[strategyId];
         if(!strategy.parameters._sell){
            revert();
        }
        if(strategy.parameters._investAmount==0){
            revert NoSwapFromZeroBalance();
        }
      
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if(strategy.parameters.current_price==CURRENT_PRICE.SELL_CURRENT){
            strategy.parameters._sellValue=price;
            strategy.sellAt=price;
            strategy.parameters._sellType=SellLegType.LIMIT_PRICE;
            strategy.parameters.current_price=CURRENT_PRICE.NOT_SELECTED;
               
        }
        uint256 sellValue=strategy.sellAt;

        if(strategy.parameters._highSellValue!=0&&(strategy.parameters._str||strategy.parameters._sellTwap)){
           sellValue=strategy.parameters._highSellValue;
           if(price<strategy.parameters._highSellValue){
            revert();
           }
        }
         else if(strategy.parameters._str||strategy.parameters._sellTwap){
            revert();
        }
        
        transferSell(strategy,strategy.parameters._investAmount,dex,callData,price,roundId,sellValue);

     
        if (!strategy.parameters._buy) {
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
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._stableToken, strategy.parameters._investToken);
        if(strategy.parameters.current_price==CURRENT_PRICE.SELL_CURRENT){
            strategy.parameters._sellValue=price;
            strategy.sellAt=price;
            strategy.parameters._sellType=SellLegType.LIMIT_PRICE;
            strategy.parameters.current_price=CURRENT_PRICE.NOT_SELECTED;
               
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
        strategy.sellTwapExecutedAt=block.timestamp;
        transferSell(strategy,value,dex,callData,price,roundId,strategy.sellAt);
        
        if(!strategy.parameters._buy&&strategy.parameters._investAmount==0){
            strategy.status=Status.COMPLETED;
        }
    }

    function executeSTR(uint256 strategyId, address dex, bytes calldata callData,uint80 fromRoundId,uint80 toRoundId) public{
        Strategy storage strategy = s.strategies[strategyId];
        
        if(!strategy.parameters._str){
                revert();
        }
        if(strategy.parameters._investAmount==0){
               revert NoSwapFromZeroBalance();
        }
   (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken,strategy.parameters._stableToken);
      
       if(strategy.parameters.current_price==CURRENT_PRICE.SELL_CURRENT){
            strategy.parameters._sellValue=price;
            strategy.sellAt=price;
            strategy.parameters._sellType=SellLegType.LIMIT_PRICE;
            strategy.parameters.current_price=CURRENT_PRICE.NOT_SELECTED;
               
        }
         
        uint256 highSellValue=strategy.parameters._highSellValue;
        if(strategy.parameters._highSellValue==0){
            highSellValue = type(uint).max;
        }
        checkRoundDataMistmatch(strategy,fromRoundId,toRoundId);
        // uint256 botPrice=LibPrice.getRoundData(botRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
        uint256 sellValue=strategy.sellAt;
        if(strategy.strLastTrackedPrice!=0){
           sellValue=strategy.strLastTrackedPrice;
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
            transferSell(strategy,value,dex,callData,price,roundId,sellValue);
            strategy.strLastTrackedPrice=price;
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
            transferSell(strategy,value,dex,callData,price,roundId,sellValue);
            strategy.strLastTrackedPrice=price;

            }
          } else if (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE) {
            uint256 priceToSTR = strategy.strLastTrackedPrice-strategy.parameters._strValue;
            if (priceToSTR<=price) {
              transferSell(strategy,value,dex,callData,price,roundId,sellValue);
              strategy.strLastTrackedPrice=price;

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
                transferSell(strategy,value,dex,callData,price,roundId,sellValue);
                strategy.strLastTrackedPrice=price;

            } 
          }
            else if (strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE) {
            uint256 priceToSTR = strategy.strLastTrackedPrice+strategy.parameters._strValue;
            
            if (price>highSellValue) {
              strategy.strLastTrackedPrice = price;
            } else if (priceToSTR>=strategy.strLastTrackedPrice) {
            transferSell(strategy,value,dex,callData,price,roundId,sellValue);
            strategy.strLastTrackedPrice=price;

            }
          }
        }
    }
   if(!strategy.parameters._buy&&strategy.parameters._investAmount==0){
            strategy.status=Status.COMPLETED;
    }
}


    function transferSell(Strategy memory strategy,uint256 value,address dex, bytes calldata callData, uint256 price,uint80 roundId,uint256 sellValue) internal{
        LibSwap.SwapData memory swap = LibSwap.SwapData(
            dex,
            strategy.parameters._investToken,
            strategy.parameters._stableToken,
            value,
            callData,
            strategy.user
        );

        uint256 toTokenAmount = LibSwap.swap(swap);

        uint256 rate = LibTrade.calculateExchangeRate(strategy.parameters._investToken, value, toTokenAmount);
        
       
        
        if (rate < sellValue) {
            revert InvalidExchangeRate(
                sellValue,
                rate
            );
        }
        if(!strategy.parameters._str){
            LibTrade.validateSlippage(rate, price, strategy.parameters._slippage, false);
        }

      strategy.totalSellDCAInvestment = strategy.totalSellDCAInvestment + toTokenAmount;
      strategy.parameters._investAmount = strategy.parameters._investAmount - value;
      strategy.parameters._stableAmount = strategy.parameters._stableAmount + toTokenAmount;

      uint256 totalInvestAmount = strategy.parameters._investAmount * strategy.investPrice;
      uint256 sum = strategy.parameters._stableAmount + totalInvestAmount;

    if (strategy.budget < sum) {
        strategy.parameters._stableAmount = strategy.budget - totalInvestAmount;

        if (strategy.profit == 0) {
            strategy.profit = 0;
        }

        strategy.profit = sum - strategy.budget + strategy.profit;
    }

        

        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount-=value;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
        if ((strategy.parameters._buyTwap||strategy.parameters._btd) && strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
         strategy.buyPercentageAmount = (strategy.parameters._buyDCAValue * strategy.parameters._stableAmount) / 100;
     }
       
    }

    function checkRoundDataMistmatch(Strategy memory strategy,uint80 fromRoundId,uint80 toRoundId) view internal{
     if(fromRoundId==0||toRoundId==0||strategy.strLastTrackedPrice==0){
        return;
     }

     uint8 decimals = IERC20Metadata(strategy.parameters._stableToken).decimals();
     int256 priceDecimals = int256(100*(10 ** uint256(decimals)));
     uint256 fromPrice=LibPrice.getRoundData(fromRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
     uint256 toPrice=LibPrice.getRoundData(toRoundId, strategy.parameters._investToken,strategy.parameters._stableToken);
     if(strategy.parameters._strType==DIP_SPIKE.FIXED_INCREASE){
        if(!(int(strategy.parameters._strValue)>=int(toPrice-fromPrice)))
        {
            revert();
        }
     }
     else if(strategy.parameters._strType==DIP_SPIKE.FIXED_DECREASE){
         if(!(int(strategy.parameters._strValue)>=int(fromPrice-toPrice))){
          revert();
         }    
     }
     else if(strategy.parameters._strType==DIP_SPIKE.INCREASE_BY){
      if(!(int(strategy.parameters._strValue)>=(int256(toPrice - fromPrice) * priceDecimals / int256(fromPrice)))){
        revert();
      }
     }
     else if(strategy.parameters._strType==DIP_SPIKE.DECREASE_BY){
          if(!(int(strategy.parameters._strValue)>=(int256(fromPrice-toPrice) * priceDecimals / int256(fromPrice)))){
        revert();
      }
     }
}
   
}