// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorage } from "../AppStorage.sol";

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner {
        require(msg.sender == s.owner, "Modifiers: Must be contract owner");
        _;
    }
}