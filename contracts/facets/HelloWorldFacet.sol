// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HelloWorldFacet {
    function getMessage() public pure returns (string memory) {
        return "Hello, World!";
    }
}
