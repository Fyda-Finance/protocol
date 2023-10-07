// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;

    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    
    // owner of the contract
    address owner;
}