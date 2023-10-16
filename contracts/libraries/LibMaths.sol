// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
error PercentageGreaterThan100();
library MathLibrary {
    function getPercentageOfNumber(uint256 percentage, uint256 total) internal pure returns (uint256) {
        if(percentage > 100){
            revert PercentageGreaterThan100();
        }
        return (total * percentage) / 100;
    }
}


