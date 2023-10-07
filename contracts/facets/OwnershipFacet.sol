// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { Modifiers } from "../utils/Modifiers.sol";

contract OwnershipFacet is IERC173, Modifiers {
    function transferOwnership(address _newOwner) external override onlyOwner {
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = s.owner;
    }
}
