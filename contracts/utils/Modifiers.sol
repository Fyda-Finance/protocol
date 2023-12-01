// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, FloorLegType, BuyLegType, SellLegType, TimeUnit, DIP_SPIKE, DCA_UNIT, CURRENT_PRICE, ReentrancyStatus } from "../AppStorage.sol";
import { ReentrancyGuardReentrantCall } from "./GenericErrors.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Modifiers {
    /// @notice 100% = 100000 -> 2 decimals

    modifier onlyOwner() {
        AppStorage storage s = LibDiamond.diamondStorage();
        require(msg.sender == s.owner, "Modifiers: Must be contract owner");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        AppStorage storage s = LibDiamond.diamondStorage();
        // On the first call to nonReentrant, s.reentrancyStatus will be ReentrancyStatus.NOT_ENTERED
        if (s.reentrancyStatus == ReentrancyStatus.ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        s.reentrancyStatus = ReentrancyStatus.ENTERED;
    }

    function _nonReentrantAfter() private {
        AppStorage storage s = LibDiamond.diamondStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        s.reentrancyStatus = ReentrancyStatus.NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        AppStorage storage s = LibDiamond.diamondStorage();
        return s.reentrancyStatus == ReentrancyStatus.ENTERED;
    }
}
