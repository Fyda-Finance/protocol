// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimeUnit } from "../AppStorage.sol";

library LibTime {
    function convertToSeconds(uint256 time, TimeUnit unit) public pure returns (uint256) {
        if (unit == TimeUnit.HOURS) {
            return time * 3600;
        } else if (unit == TimeUnit.DAYS) {
            return time * 86400;
        } else {
            revert();
        }
    }

    function getTimeDifference(uint256 blockTime,uint256 presentTime, uint256 targetTime) public pure returns (bool) {
        bool timeDifference = targetTime > blockTime-presentTime ? true : false;
        return timeDifference;
    }
}


