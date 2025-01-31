// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import { ERC4626, ERC20 } from "solady/tokens/ERC4626.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solady/utils/ReentrancyGuard.sol";
import { UtilsLib } from "morpho/libraries/UtilsLib.sol";
import { ITeller } from "./interfaces/ITeller.sol";
import { AAccessControl } from "./utils/AAccessControl.sol";
import { Initializable } from "solady/utils/Initializable.sol";
import { AccessControl } from "./AccessControl.sol";

/// @title Wrapper contract
/// @notice Contract to wrap a boring vault and auto compound the profits
/// @author 0xtekgrinder
contract Wrapper is ERC4626, ReentrancyGuard, AAccessControl, Initializable  {
    using SafeTransferLib for address;
    using UtilsLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the vesting period is updated
     */
    event VestingPeriodUpdated(uint256 newVestingPeriod);

    /*//////////////////////////////////////////////////////////////
                          CONSTANTS VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Address of the definitive asset()
     */
    address private _asset;
    /**
     * @notice Name of the vault
     */
    string private _name;
    /**
     * @notice Symbol of the vault
     */
    string private _symbol;

    /*//////////////////////////////////////////////////////////////
                            MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The number of decimals of the vault
     */
    uint8 private _decimals;
    /**
     * @notice The vesting period of the rewards
     */
    uint64 public vestingPeriod;
    /**
     * @notice The last update of the vesting
     */
    uint64 public lastUpdate;
    /**
     * @notice The profit that is locked in the strategy
     */
    uint256 public vestingProfit;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function init(
        uint64 initialVestingPeriod,
        address definitiveAccessControl,
        string memory definitiveName,
        string memory definitiveSymbol
    ) initializer external {
        _initAAccessControl(definitiveAccessControl);

        _asset = AccessControl(definitiveAccessControl).metaVault();
        _decimals = ERC20(_asset).decimals();

        _name = definitiveName;
        _symbol = definitiveSymbol;

        vestingPeriod = initialVestingPeriod;
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the vesting period
     * @param newVestingPeriod The new vesting period
     */
    function setVestingPeriod(uint64 newVestingPeriod) external onlyCurator {
        vestingPeriod = newVestingPeriod;

        emit VestingPeriodUpdated(newVestingPeriod);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Computes the current amount of locked profit
     * @dev This function is what effectively vests profits
     * @return The amount of locked profit
     */
    function lockedProfit() public view virtual returns (uint256) {
        // Get the last update and vesting delay.
        uint64 _lastUpdate = lastUpdate;
        uint64 _vestingPeriod = vestingPeriod;

        unchecked {
            // If the vesting period has passed, there is no locked profit.
            // This cannot overflow on human timescales
            if (block.timestamp >= _lastUpdate + _vestingPeriod) return 0;

            // Get the maximum amount we could return.
            uint256 currentlyVestingProfit = vestingProfit;

            // Compute how much profit remains locked based on the last time a profit was acknowledged
            // and the vesting period. It's impossible for an update to be in the future, so this will never underflow.
            return currentlyVestingProfit - (currentlyVestingProfit * (block.timestamp - _lastUpdate)) / _vestingPeriod;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the name of the token
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ERC4626
     * @dev asset is the definitive asset of the wrapper (stkscUSD)
     */
    function asset() public view override returns (address) {
        return _asset;
    }

    /**
     * @inheritdoc ERC4626
     */
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets().zeroFloorSub(lockedProfit()); // handle rounding down of assets
    }

    /**
     * @inheritdoc ERC4626
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                            HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Propagates a gain
     * @param gain Gain to propagate
     */
    function _handleGain(uint256 gain) internal virtual {
        if (gain != 0) {
            vestingProfit = uint128(lockedProfit() + gain);
            lastUpdate = uint32(block.timestamp);
        }
    }

    /**
     * @notice Add yield to the vault
     * @param collateral Collateral to add yield to
     * @param amount Amount of collateral to add yield to
     */
    function addYield(address collateral, uint256 amount) public nonReentrant onlyMetaVaultOrCuratorOrOperator {
        address _vault = AccessControl(accessControl).metaVault();
        address _teller = AccessControl(accessControl).teller();

        // pull tokens
        collateral.safeTransferFrom(msg.sender, address(this), amount);

        // mint the vault shares fron the teller
        collateral.safeApprove(_vault, amount);
        uint256 sharesOut = ITeller(_teller).deposit(collateral, amount, address(this));
        _handleGain(sharesOut);
    }
}