// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function decimals() external view returns (uint8);
}
