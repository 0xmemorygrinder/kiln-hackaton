// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";
import { Initializable } from "solady/utils/Initializable.sol";

contract AccessControl is OwnableRoles, Initializable {
    address public metaVault;
    address public staker;
    address public teller;
    address public accountant;
    address public curator;
    address public treasury;

    uint256 public constant OPERATOR_ROLE = 10000;

    function init(
        address _metaVault,
        address _staker,
        address _teller,
        address _accountant,
        address _curator,
        address _treasury
    ) initializer external {
        _initializeOwner(_curator);

        metaVault = _metaVault;
        staker = _staker;
        teller = _teller;
        accountant = _accountant;
        curator = _curator;
        treasury = _treasury;
    }

    function isCurator(address account) external view returns (bool) {
        return account == curator;
    }

    function isTreasury(address account) external view returns (bool) {
        return account == treasury;
    }

    function isOperator(address account) external view returns (bool) {
        return hasAnyRole(account, OPERATOR_ROLE);
    }

    function isMetaVault(address account) external view returns (bool) {
        return account == metaVault;
    }
}