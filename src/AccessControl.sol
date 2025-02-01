// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";
import { Initializable } from "solady/utils/Initializable.sol";

/// @title AccessControl
/// @notice This contract manages the roles of the different contracts in the system and keep a registry of the
/// definitive contracts
/// @author 0xtekgrinder and 0xMemoryGrinder
contract AccessControl is OwnableRoles, Initializable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the curator is updated
     */
    event CuratorUpdated(address newCurator);
    /**
     * @notice Event emitted when the treasury is updated
     */
    event TreasuryUpdated(address newTreasury);

    /*//////////////////////////////////////////////////////////////
                          CONSTANTS VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Role identifier for the operator role
     */
    uint256 public constant OPERATOR_ROLE = 10_000;

    /**
     * @notice The metaVault address
     */
    address public metaVault;
    /**
     * @notice The staker address
     */
    address public staker;
    /**
     * @notice The teller address
     */
    address public teller;
    /**
     * @notice The accountant address
     */
    address public accountant;

    /*//////////////////////////////////////////////////////////////
                         MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The curator address
     */
    address public curator;
    /**
     * @notice The treasury address
     */
    address public treasury;

    /*//////////////////////////////////////////////////////////////
                          INITIALIZER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the contract with the definitive contracts
     * @param definitiveMetaVault The definitive metaVault address
     * @param definitiveStaker The definitive staker address
     * @param definitiveTeller The definitive teller address
     * @param definitiveAccountant The definitive accountant address
     * @param initialCurator The initial curator address
     * @param initialTreasury The initial treasury address
     */
    function init(
        address definitiveMetaVault,
        address definitiveStaker,
        address definitiveTeller,
        address definitiveAccountant,
        address initialCurator,
        address initialTreasury
    ) external initializer {
        _initializeOwner(initialCurator);

        metaVault = definitiveMetaVault;
        staker = definitiveStaker;
        teller = definitiveTeller;
        accountant = definitiveAccountant;

        curator = initialCurator;
        treasury = initialTreasury;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the account is the curator
     * @param account The account to check
     * @return True if the account is the curator
     */
    function isCurator(address account) external view returns (bool) {
        return account == curator;
    }

    /**
     * @notice Check if the account is the treasury
     * @param account The account to check
     * @return True if the account is the treasury
     */
    function isTreasury(address account) external view returns (bool) {
        return account == treasury;
    }

    function getMetaVault() public view returns (address) {
        return metaVault;
    }

    /**
     * @notice Check if the account is the operator
     * @param account The account to check
     * @return True if the account is the operator
     */
    function isOperator(address account) external view returns (bool) {
        return hasAnyRole(account, OPERATOR_ROLE);
    }

    /**
     * @notice Check if the account is the metaVault
     * @param account The account to check
     * @return True if the account is the metaVault
     */
    function isMetaVault(address account) external view returns (bool) {
        return account == metaVault;
    }

    /**
     * @notice Check if the account is the teller
     * @param account The account to check
     * @return True if the account is the teller
     */
    function isTeller(address account) external view returns (bool) {
        return account == teller;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the new curator
     * @param newCurator The new curator address
     */
    function setCurator(address newCurator) external onlyOwner {
        emit CuratorUpdated(newCurator);

        _setOwner(newCurator);
        curator = newCurator;
    }

    /**
     * @notice Set the new treasury
     * @param newTreasury The new treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        emit TreasuryUpdated(newTreasury);

        treasury = newTreasury;
    }
}
