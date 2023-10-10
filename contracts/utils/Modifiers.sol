// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage } from "../AppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Modifiers {
    modifier onlyOwner {
        AppStorage storage s = LibDiamond.diamondStorage();
        require(msg.sender == s.owner, "Modifiers: Must be contract owner");
        _;
    }
}