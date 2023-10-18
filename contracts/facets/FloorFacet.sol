
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage, Strategy, Status  } from "../AppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import {LibTrade} from "../libraries/LibTrade.sol";
import { InvalidExchangeRate,  NoSwapFromZeroBalance } from "../utils/GenericErrors.sol";




contract FloorFacet is Modifiers {
    AppStorage internal s;

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

       uint256 rate = LibTrade.calculateExchangeRate(strategy.parameters._investToken, strategy.parameters._investAmount, toTokenAmount);

        if (rate > strategy.floorAt) {
            revert InvalidExchangeRate(
                strategy.floorAt,
                rate
            );
        }

        //   now compare with chainlink
        (uint256 price,uint80 roundId) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        LibTrade.validateSlippage(rate, price, strategy.parameters._slippage, false);
        strategy.timestamp=block.timestamp;
        strategy.parameters._investAmount=0;
        strategy.parameters._stableAmount+=toTokenAmount;
        strategy.roundId=roundId;
        if(strategy.parameters._cancelOnFloor){
            strategy.status=Status.CANCELLED;
        }
}
        
    }

   
}