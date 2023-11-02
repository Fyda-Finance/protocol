// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { AppStorage } from "../AppStorage.sol";

/**
 * @title OwnershipFacet
 * @dev This contract handles the ownership management of the diamond contract.
 */
contract OwnershipFacet is IERC173, Modifiers {
  AppStorage internal s;

  /**
   * @notice Transfers ownership of the diamond contract to a new owner.
   * @param _newOwner The address of the new owner.
   */
  function transferOwnership(address _newOwner) external override onlyOwner {
    LibDiamond.setContractOwner(_newOwner);
  }

  /**
   * @notice Retrieves the current owner of the diamond contract.
   */
  function owner() external view override returns (address owner_) {
    owner_ = s.owner;
  }
}
