// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimeUnit } from "../AppStorage.sol";

error InvalidUnit();

/**
 * @title LibTime
 * @dev This library provides functions for time-related calculations.
 */
library LibTime {
    /**
     * @notice Convert a given time value to seconds based on the specified time unit.
     * @param time The time value to convert.
     * @param unit The time unit (e.g., TimeUnit.HOURS, TimeUnit.DAYS).
     * @return The time value converted to seconds.
     * @dev Reverts with `InvalidUnit` error if an unsupported time unit is provided.
     */
    function convertToSeconds(uint256 time, TimeUnit unit) internal pure returns (uint256) {
        if (unit == TimeUnit.HOURS) {
            return time * 3600;
        } else if (unit == TimeUnit.DAYS) {
            return time * 86400;
        } else {
            revert InvalidUnit();
        }
    }

    /**
     * @notice Check if a time difference condition is met.
     * @param presentTime The current time.
     * @param executionTime The execution time to consider (0 for immediate execution).
     * @param targetTime The target time for comparison.
     * @return A boolean indicating whether the time difference condition is met.
     */

    function getTimeDifference(
        uint256 presentTime,
        uint256 executionTime,
        uint256 targetTime
    ) internal pure returns (bool) {
        if (executionTime == 0) {
            return true;
        }
        bool timeDifference = targetTime <= presentTime - executionTime ? true : false;
        return timeDifference;
    }
}
