// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// AccessControl errors

error UnauthorizedAccess();

// Accountant errors

error CollateralDoesNotExist();
error CollateralAlreadyExists();
error WrongCollateral();
error WrongOracle();
error WrongFee();
error WrongBound();
error NegativeValue();