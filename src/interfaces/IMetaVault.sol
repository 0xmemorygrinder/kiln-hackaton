// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

interface IMetaVault {
  struct Bound {
    uint128 lower;
    uint128 upper;
  }
  struct RevenueSharing {
    address recipient;
    uint256 weight;
  }

  function deposit(address asset, uint256 mintAmount, uint256 amount, address from, address to) external;

  function withdraw(address asset, uint256 burnAmount, uint256 amount, address from, address to) external;
}