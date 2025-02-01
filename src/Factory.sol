// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {ERC1967Factory} from "solady/utils/ERC1967Factory.sol";
import {AccessControl} from "./AccessControl.sol";
import {MetaVault} from "./MetaVault.sol";
import {Staking} from "./Staking.sol";
import {Teller} from "./Teller.sol";
import {Accountant} from "./Accountant.sol";
import {TransparentUpgradeableProxy} from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./utils/Errors.sol";

/// @title Factory
/// @notice This contract is the factory for the different contracts in the system
/// @author 0xtekgrinder
contract Factory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the stablecoin is deployed
     */
    event StablecoinDeployed(address accountant, address teller, address metaVault, address staking, address accessControl);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct to store the addresses of the different contracts in the system
     * @param accountant The accountant address
     * @param teller The teller address
     * @param metaVault The metaVault address
     * @param staking The staking address (optional)
     * @param accessControl The accessControl address
     * @param strategiesRegistry The strategiesRegistry address
     */
    struct StablecoinAddresses {
        address accountant;
        address teller;
        address metaVault;
        address staking;
        address accessControl;
        address strategiesRegistry;
    }

    /**
     * @notice Struct to store the arguments for the staking contract
     */
    struct StakingArguments {
        uint64 vestingPeriod;
        string name;
        string symbol;
    }

    /**
     * @notice Struct to store the arguments for the metaVault contract
     */
    struct MetaVaultArguments {
        address endpoint;
        string name;
        string symbol;
        uint8 decimals;
    }

    /*//////////////////////////////////////////////////////////////
                          IMMUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The admin address of the system
     */
    address public immutable admin;

    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/


    /**
     * @notice The addresses of the different implementation contracts in the system
     */
    StablecoinAddresses public stablecoinImplementationAddresses;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address definitiveAdmin) {
        admin = definitiveAdmin;
    }

    /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys the stablecoin contracts without the staking contract
     * @param curator The curator address
     * @param treasury The treasury address
     * @param vaultInitData The metaVault initialization data
     */
    function deployStablecoin(address curator, address treasury, MetaVaultArguments calldata vaultInitData) external {
        StablecoinAddresses memory stablecoinAddresses = stablecoinImplementationAddresses;
        address _admin = admin;
        address accessControl = deploy(stablecoinAddresses.accessControl, _admin);

        address accountant = deploy(stablecoinAddresses.accountant, _admin);
        address teller = deploy(stablecoinAddresses.teller, _admin);
        address metaVault = deploy(stablecoinAddresses.metaVault, _admin);
        AccessControl(accessControl).init(metaVault, address(0), teller, accountant, curator, treasury);
        Accountant(accountant).init(accessControl);
        Teller(teller).init(accessControl);
        MetaVault(metaVault).init(accessControl, stablecoinAddresses.strategiesRegistry, vaultInitData.endpoint, vaultInitData.name, vaultInitData.symbol, vaultInitData.decimals);

        emit StablecoinDeployed(accountant, teller, metaVault, address(0), accessControl);
    }

    /**
     * @notice Deploys the stablecoin contracts with the staking contract
     * @param curator The curator address
     * @param treasury The treasury address
     * @param vaultInitData The metaVault initialization data
     * @param stakingInitData The staking initialization data
     */
    function deployStablecoin(address curator, address treasury, MetaVaultArguments calldata vaultInitData, StakingArguments calldata stakingInitData) external {
        StablecoinAddresses memory stablecoinAddresses = stablecoinImplementationAddresses;
        address _admin = admin;
        address accessControl = deploy(stablecoinAddresses.accessControl, _admin);

        address accountant = deploy(stablecoinAddresses.accountant, _admin);
        address teller = deploy(stablecoinAddresses.teller, _admin);
        address metaVault = deploy(stablecoinAddresses.metaVault, _admin);
        address staking = deploy(stablecoinAddresses.staking, _admin);
        Accountant(accountant).init(accessControl);
        Teller(teller).init(accessControl);
        MetaVault(metaVault).init(accessControl, stablecoinAddresses.strategiesRegistry, vaultInitData.endpoint, vaultInitData.name, vaultInitData.symbol, vaultInitData.decimals);
        AccessControl(accessControl).init(metaVault, staking, teller, accountant, curator, treasury);

        Staking(staking).init(stakingInitData.vestingPeriod , accessControl, stakingInitData.name, stakingInitData.symbol);

        emit StablecoinDeployed(accountant, teller, metaVault, staking, accessControl);

    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setStablecoinImplementationAddresses(StablecoinAddresses calldata _stablecoinImplementationAddresses) external {
        if (msg.sender != admin) {
            revert UnauthorizedAccess();
        }
        stablecoinImplementationAddresses = _stablecoinImplementationAddresses;
    }

    function deploy(address _implementation, address _admin) internal returns (address) {
        return address(new TransparentUpgradeableProxy(_implementation, _admin, ""));
    }
}
