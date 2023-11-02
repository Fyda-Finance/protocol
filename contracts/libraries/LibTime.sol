// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimeUnit} from "../AppStorage.sol";

error InvalidUnit();

library LibTime {
    function convertToSeconds(uint256 time, TimeUnit unit)
        internal
        pure
        returns (uint256)
    {
        if (unit == TimeUnit.HOURS) {
            return time * 3600;
        } else if (unit == TimeUnit.DAYS) {
            return time * 86400;
        } else {
            revert InvalidUnit();
        }
    }

    function getTimeDifference(
        uint256 presentTime,
        uint256 executionTime,
        uint256 targetTime
    ) internal pure returns (bool) {
        if (executionTime == 0) {
            return true;
        }
        bool timeDifference = targetTime <= presentTime - executionTime
            ? true
            : false;
        return timeDifference;
    }
}
