// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {Modifiers} from "../utils/Modifiers.sol";
import {AppStorage} from "../AppStorage.sol";

contract OwnershipFacet is IERC173, Modifiers {
    AppStorage internal s;

    function transferOwnership(address _newOwner) external override onlyOwner {
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = s.owner;
    }
}
