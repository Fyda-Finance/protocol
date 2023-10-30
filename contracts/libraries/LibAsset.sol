// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TransferFailed } from "../utils/GenericErrors.sol";
import "hardhat/console.sol";

library LibAsset {
    uint256 private constant MAX_UINT = type(uint256).max;

    function balanceOf(address asset, address account) internal view returns (uint256) {
        return IERC20(asset).balanceOf(account);
    }

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

    function transferFrom(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 prevBalance = IERC20(asset).balanceOf(to);
        uint256 userBalance = IERC20(asset).balanceOf(from);
        console.log("userBalance %s", userBalance);
        console.log("Amount %s", amount);
        SafeERC20.safeTransferFrom(IERC20(asset), from, to, amount);
        if (IERC20(asset).balanceOf(to) - prevBalance != amount) {
            revert TransferFailed();
        }
    }

    function transfer(
        address asset,
        address to,
        uint256 amount
    ) internal {
        uint256 prevBalance = IERC20(asset).balanceOf(to);
        SafeERC20.safeTransfer(IERC20(asset), to, amount);
        if (IERC20(asset).balanceOf(to) - prevBalance != amount) {
            revert TransferFailed();
        }
    }
}
