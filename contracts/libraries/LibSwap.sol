// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibAsset } from "./LibAsset.sol";
import { LibUtil } from "./LibUtil.sol";
import { NoSwapFromZeroBalance, InsufficientBalance, SwapFailed } from "../utils/GenericErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibSwap {
    struct SwapData {
        address callTo;
        address fromAsset;
        address toAsset;
        uint256 fromAmount;
        bytes callData;
        address user;
    }

    event AssetSwapped(
        address dex,
        address fromAsset,
        address toAsset,
        uint256 fromAmount,
        uint256 receivedAmount,
        address account
    );

    function swap(SwapData memory _swap) internal returns (uint256) {
        uint256 fromAmount = _swap.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();

        LibAsset.transferFrom(_swap.fromAsset, _swap.user, address(this), fromAmount);

        uint256 initialReceivingAssetBalance = LibAsset.balanceOf(_swap.toAsset, address(this));

        LibAsset.maxApprove(_swap.fromAsset, _swap.callTo, _swap.fromAmount);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.callTo.call(_swap.callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        uint256 newBalance = LibAsset.balanceOf(_swap.toAsset, address(this));
        uint256 receivedAmount = newBalance - initialReceivingAssetBalance;

        if (receivedAmount == 0) {
            revert SwapFailed();
        }

        LibAsset.transfer(_swap.toAsset, _swap.user, receivedAmount);

        emit AssetSwapped(_swap.callTo, _swap.fromAsset, _swap.toAsset, _swap.fromAmount, receivedAmount, _swap.user);

        return receivedAmount;
    }
}
