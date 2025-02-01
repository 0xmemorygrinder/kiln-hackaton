// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import "./utils/AAccessControl.sol";
import { Initializable } from "solady/utils/Initializable.sol";
import { IChainlinkOracle } from "./interfaces/IChainlinkOracle.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";

/// @title Accountant contract
/// @notice Contract to manage the minting and burning of collateral tokens withh peg mechanisms
/// @author 0xtekgrinder
contract Accountant is AAccessControl, Initializable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when a new collateral is added
     */
    event CollateralAdded(
        address collateral, address oracle, uint256 burnFee, uint256 mintFee, uint256 burnBound, uint256 mintBound
    );
    /**
     * @notice Event emitted when a collateral is removed
     */
    event CollateralRemoved(address collateral);
    /**
     * @notice Event emitted when the oracle of a collateral is updated
     */
    event CollateralOracleUpdated(address collateral, address oracle);
    /**
     * @notice Event emitted when the parameters of a collateral are updated
     */
    event CollateralParametersUpdated(
        address collateral, uint256 burnFee, uint256 mintFee, uint256 burnBound, uint256 mintBound
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CollateralsParameters {
        uint256 burnFee;
        uint256 mintFee;
        uint256 burnBound;
        uint256 mintBound;
    }

    /*//////////////////////////////////////////////////////////////
                          MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public isCollateral;
    mapping(address => address) public collateralOracles;
    mapping(address => CollateralsParameters) public collateralsParameters;
    mapping(address => uint256) public collateralsMinted;
    uint256 public totalMinted;

    /*//////////////////////////////////////////////////////////////
                          INITIALIZER FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with the definitive access control
     * @param definitiveAccessControl The address of the definitive access control
     */
    function init(address definitiveAccessControl) external initializer {
        _initAAccessControl(definitiveAccessControl);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the mint rate of a collateral
     * @param collateral The address of the collateral
     * @return The mint rate of the collateral
     */
    function getMintRate(address collateral) public view returns (uint256) {
        if (!isCollateral[collateral]) {
            revert CollateralDoesNotExist();
        }

        uint256 price = _castUint256(IChainlinkOracle(collateralOracles[collateral]).latestAnswer());
        uint8 vaultDecimals = ERC20(getMetaVault()).decimals();
        uint8 collateralDecimals = IChainlinkOracle(collateralOracles[collateral]).decimals();

        price = _scaleDecimals(price, collateralDecimals, vaultDecimals);

        uint256 collateralMinted = collateralsMinted[collateral];
        CollateralsParameters memory parameters = collateralsParameters[collateral];
        if (totalMinted * 100 / collateralMinted > parameters.mintBound) {
            price -= price * parameters.mintFee / 10_000;
        }
        return price;
    }

    function getBurnRate(address collateral) public view returns (uint256) {
        if (!isCollateral[collateral]) {
            revert CollateralDoesNotExist();
        }

        uint256 price = _castUint256(IChainlinkOracle(collateralOracles[collateral]).latestAnswer());
        uint8 vaultDecimals = ERC20(getMetaVault()).decimals();
        uint8 collateralDecimals = IChainlinkOracle(collateralOracles[collateral]).decimals();

        price = _scaleDecimals(price, collateralDecimals, vaultDecimals);

        // In case of premium over the collateral, burn 1:1
        if (price < 10 ** vaultDecimals) {
            price = 10 ** vaultDecimals;
        }

        uint256 collateralMinted = collateralsMinted[collateral];
        CollateralsParameters memory parameters = collateralsParameters[collateral];
        if (totalMinted * 100 / collateralMinted < parameters.burnBound) {
            price -= price * parameters.burnFee / 10_000;
        }
        return price;
    }

    function quoteMint(address collateral, uint256 amount) public view returns (uint256) {
        uint256 mintRate = getMintRate(collateral);
        uint256 vaultDecimals = ERC20(getMetaVault()).decimals();
        return amount * mintRate / 10 ** vaultDecimals;
    }

    function quoteBurn(address collateral, uint256 amount) public view returns (uint256) {
        uint256 burnRate = getBurnRate(collateral);
        uint256 vaultDecimals = ERC20(getMetaVault()).decimals();
        return amount * burnRate / 10 ** vaultDecimals;
    }

    /*//////////////////////////////////////////////////////////////
                          TELLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address collateral, uint256 amount) external onlyTeller returns (uint256) {
        uint256 mintAmount = quoteMint(collateral, amount);

        collateralsMinted[collateral] += mintAmount;
        totalMinted += mintAmount;

        return mintAmount;
    }

    function burn(address collateral, uint256 amount) external onlyTeller returns (uint256) {
        uint256 burnAmount = quoteBurn(collateral, amount);

        collateralsMinted[collateral] -= burnAmount;
        totalMinted -= burnAmount;

        return burnAmount;
    }

    /*//////////////////////////////////////////////////////////////
                          CURATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new collateral to the system
     * @param collateral The address of the collateral
     * @param oracle The address of the oracle
     * @param burnFee The burn fee of the collateral
     * @param mintFee The mint fee of the collateral
     * @param burnBound The burn bound of the collateral
     * @param mintBound The mint bound of the collateral
     */
    function addCollateral(
        address collateral,
        address oracle,
        uint256 burnFee,
        uint256 mintFee,
        uint256 burnBound,
        uint256 mintBound
    ) external onlyCurator {
        if (collateral == address(0)) {
            revert WrongCollateral();
        }
        if (oracle == address(0)) {
            revert WrongOracle();
        }
        if (isCollateral[collateral]) {
            revert CollateralAlreadyExists();
        }
        if (burnFee > 10_000) {
            revert WrongFee();
        }
        if (mintFee > 10_000) {
            revert WrongFee();
        }
        if (burnBound > 10_000) {
            revert WrongBound();
        }
        if (mintBound > 10_000) {
            revert WrongBound();
        }
        if (burnBound > mintBound) {
            revert WrongBound();
        }

        isCollateral[collateral] = true;
        collateralOracles[collateral] = oracle;
        collateralsParameters[collateral] = CollateralsParameters(burnFee, mintFee, burnBound, mintBound);

        emit CollateralAdded(collateral, oracle, burnFee, mintFee, burnBound, mintBound);
    }

    /**
     * @notice Remove a collateral from the system
     * @param collateral The address of the collateral
     */
    function removeCollateral(address collateral) external onlyCurator {
        if (!isCollateral[collateral]) {
            revert CollateralDoesNotExist();
        }

        isCollateral[collateral] = false;
        delete collateralOracles[collateral];
        delete collateralsParameters[collateral];

        emit CollateralRemoved(collateral);
    }

    /**
     * @notice Set the oracle of a collateral
     * @param collateral The address of the collateral
     * @param oracle The address of the oracle
     */
    function setCollateralOracle(address collateral, address oracle) external onlyCurator {
        if (!isCollateral[collateral]) {
            revert CollateralDoesNotExist();
        }

        collateralOracles[collateral] = oracle;

        emit CollateralOracleUpdated(collateral, oracle);
    }

    /**
     * @notice Set the parameters of a collateral
     * @param collateral The address of the collateral
     * @param burnFee The burn fee of the collateral
     * @param mintFee The mint fee of the collateral
     * @param burnBound The burn bound of the collateral
     * @param mintBound The mint bound of the collateral
     */
    function setCollateralsParameters(
        address collateral,
        uint256 burnFee,
        uint256 mintFee,
        uint256 burnBound,
        uint256 mintBound
    ) external onlyCurator {
        if (!isCollateral[collateral]) {
            revert CollateralDoesNotExist();
        }
        if (burnFee > 10_000) {
            revert WrongFee();
        }
        if (mintFee > 10_000) {
            revert WrongFee();
        }
        if (burnBound > 10_000) {
            revert WrongBound();
        }
        if (mintBound > 10_000) {
            revert WrongBound();
        }
        if (burnBound > mintBound) {
            revert WrongBound();
        }

        collateralsParameters[collateral] = CollateralsParameters(burnFee, mintFee, burnBound, mintBound);

        emit CollateralParametersUpdated(collateral, burnFee, mintFee, burnBound, mintBound);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _scaleDecimals(uint256 amount, uint8 from, uint8 to) internal pure returns (uint256) {
        if (from == to) {
            return amount;
        }

        return amount * (10 ** (to - from));
    }

    function _castUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert NegativeValue();
        }
        return uint256(value);
    }
}
