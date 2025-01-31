// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface ITeller {
    function deposit(address asset, uint256 amount, address recipient) external returns (uint256);
}