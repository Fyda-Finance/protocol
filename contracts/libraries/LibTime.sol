// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimeUnit } from "../AppStorage.sol";
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
    uint256 blockTime,
    uint256 presentTime,
    uint256 targetTime
  ) internal pure returns (bool) {
    bool timeDifference = targetTime > blockTime - presentTime ? true : false;
    return timeDifference;
  }
}
