// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferFailed} from "../utils/GenericErrors.sol";

/**
 * @title LibAsset
 * @dev This library provides functions for interacting with ERC20 assets.
 */
library LibAsset {
    uint256 private constant MAX_UINT = type(uint256).max;

    /**
     * @notice Approves a specified amount of an asset for a spender if the current allowance is insufficient.
     * @param asset The address of the asset.
     * @param spender The address of the spender.
     * @param amount The amount to approve.
     */
    function maxApprove(
        address asset,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(asset).allowance(address(this), spender) < amount) {
            SafeERC20.safeApprove(IERC20(asset), spender, 0);
            SafeERC20.safeApprove(IERC20(asset), spender, amount);
        }
    }

    /**
     * @notice Transfers a specified amount of an asset from one address to another.
     * @param asset The address of the asset.
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param amount The amount to transfer.
     */
    function transferFrom(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 prevBalance = IERC20(asset).balanceOf(to);
        SafeERC20.safeTransferFrom(IERC20(asset), from, to, amount);
        if (IERC20(asset).balanceOf(to) - prevBalance != amount) {
            revert TransferFailed();
        }
    }

    /**
     * @notice Transfers a specified amount of an asset to a recipient.
     * @param asset The address of the asset.
     * @param to The recipient's address.
     * @param amount The amount to transfer.
     */
    function transfer(address asset, address to, uint256 amount) internal {
        uint256 prevBalance = IERC20(asset).balanceOf(to);
        SafeERC20.safeTransfer(IERC20(asset), to, amount);
        if (IERC20(asset).balanceOf(to) - prevBalance != amount) {
            revert TransferFailed();
        }
    }

    /**
     * @notice Retrieves the balance of a specified asset for a given account.
     * @param asset The address of the asset.
     * @param account The account for which to check the balance.
     * @return The balance of the asset for the specified account.
     */
    function balanceOf(
        address asset,
        address account
    ) internal view returns (uint256) {
        return IERC20(asset).balanceOf(account);
    }
}
