// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";

contract AccessControl is OwnableRoles {
    address public metaVault;
    address public staker;
    address public teller;
    address public accountant;
    address public curator;
    address public treasury;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(
        address _metaVault,
        address _staker,
        address _teller,
        address _accountant,
        address _curator,
        address _treasury,
        address _initialOperator,
    ) {
        metaVault = _metaVault;
        staker = _staker;
        teller = _teller;
        accountant = _accountant;
        curator = _curator;
        treasury = _treasury;
        grantRole(OPERATOR_ROLE, _initialOperator);
    }
    
    function isCurator(address account) external view returns (bool) {
        return account == curator;
    }

    function isTreasury(address account) external view returns (bool) {
        return account == treasury;
    }

    function isOperator(address account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }
}