// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage } from "../AppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Modifiers {
    /// @notice 100% = 100000 -> 2 decimals
    uint256 constant MAX_PERCENTAGE = 10000;

    modifier onlyOwner {
        AppStorage storage s = LibDiamond.diamondStorage();
        require(msg.sender == s.owner, "Modifiers: Must be contract owner");
        _;
    }
}