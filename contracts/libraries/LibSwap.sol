// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAsset} from "./LibAsset.sol";
import {LibUtil} from "./LibUtil.sol";
import {NoSwapFromZeroBalance, InsufficientBalance, SwapFailed} from "../utils/GenericErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LibSwap
 * @dev This library provides functions for executing asset swaps.
 */
library LibSwap {
    struct SwapData {
        address callTo; // The address of the contract or dex to execute the swap on.
        address fromAsset; // The address of the asset to swap from.
        address toAsset; // The address of the asset to receive.
        uint256 fromAmount; // The amount of the 'fromAsset' to swap.
        bytes callData; // The call data for the swap.
        address user; // The user initiating the swap.
    }

    /**
     * @notice Emitted when an asset swap has been executed successfully.
     * @param dex The address of the contract or dex used for the swap.
     * @param fromAsset The address of the asset swapped from.
     * @param toAsset The address of the asset received in the swap.
     * @param fromAmount The amount of 'fromAsset' that was swapped.
     * @param receivedAmount The amount of 'toAsset' received in the swap.
     * @param account The address of the user account that initiated the swap.
     */

    event AssetSwapped(
        address dex,
        address fromAsset,
        address toAsset,
        uint256 fromAmount,
        uint256 receivedAmount,
        address account
    );

    /**
     * @notice Execute an asset swap from one asset to another using the provided swap data.
     * @param _swap The swap data containing all necessary information for the swap.
     * @return The amount of 'toAsset' received in the swap.
     * @dev This function transfers 'fromAsset' from the user to this contract, executes the swap,
     * and transfers the received 'toAsset' back to the user.
     */
    function swap(SwapData memory _swap) internal returns (uint256) {
        uint256 fromAmount = _swap.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();

        LibAsset.transferFrom(
            _swap.fromAsset,
            _swap.user,
            address(this),
            fromAmount
        );

        uint256 initialReceivingAssetBalance = LibAsset.balanceOf(
            _swap.toAsset,
            address(this)
        );

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

        emit AssetSwapped(
            _swap.callTo,
            _swap.fromAsset,
            _swap.toAsset,
            _swap.fromAmount,
            receivedAmount,
            _swap.user
        );

        return receivedAmount;
    }
}
