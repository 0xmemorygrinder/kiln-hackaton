// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Errors.sol";
import { AccessControl } from "../AccessControl.sol";

abstract contract AAccessControl {
    address public accessControl;

    modifier onlyTreasury() {
        if (!AccessControl(accessControl).isTreasury(msg.sender)) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyOperator() {
        if (!AccessControl(accessControl).isOperator(msg.sender)) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyCurator() {
        if (!AccessControl(accessControl).isCurator(msg.sender)) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyOperatorOrCurator() {
        if (!AccessControl(accessControl).isOperator(msg.sender) && !AccessControl(accessControl).isCurator(msg.sender))
        {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyMetaVault() {
        if (!AccessControl(accessControl).isMetaVault(msg.sender)) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyTeller() {
        if (!AccessControl(accessControl).isTeller(msg.sender)) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier onlyMetaVaultOrCuratorOrOperator() {
        if (
            !AccessControl(accessControl).isMetaVault(msg.sender) && !AccessControl(accessControl).isCurator(msg.sender)
                && !AccessControl(accessControl).isOperator(msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _;
    }

    function _initAAccessControl(address definitiveAccessControl) internal {
        accessControl = definitiveAccessControl;
    }

    function getMetaVault() public view returns (address) {
        return AccessControl(accessControl).getMetaVault();
    }

    function getAccountant() public view returns (address) {
        return AccessControl(accessControl).accountant();
    }
}
