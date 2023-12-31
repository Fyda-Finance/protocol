// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibBytes.sol";

/**
 * @title LibUtil
 * @dev This library provides utility functions for working with revert messages.
 */
library LibUtil {
    using LibBytes for bytes;

    /**
     * @notice Get a revert message from transaction result data.
     * @param _res The transaction result data to extract the revert message from.
     * @return string The revert message or a "Transaction reverted silently" message if none is found.
     */
    function getRevertMsg(bytes memory _res) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /**
     * @notice Used the get the ID of the current chain.
     * @return id The chain ID
     */
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
