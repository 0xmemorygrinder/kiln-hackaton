// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Initializable } from "solady/utils/Initializable.sol";
import { ERC4626 } from "solady/tokens/ERC4626.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { OFTUpgradeable } from "./lib/lz-oft-upgradeable/OFTUpgradeable.sol";
import { IMetaVault } from "./interfaces/IMetaVault.sol";
import { AAccessControl, AccessControl } from "./utils/AAccessControl.sol";
import { Allowance } from "./utils/Allowance.sol";
import { StrategiesRegistry } from "./StrategiesRegistry.sol";

/// @title MetaVault
/// @notice This contract manages the strategies and the assets of the vault and issues the stablecoin tokens
/// @author 0xMemoryGrinder and 0xTekGrinder
contract MetaVault is OFTUpgradeable, AAccessControl {
  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Error emitted when the strategy is invalid
   * @param strategy The address of the strategy that is invalid
   */
  error InvalidStrategy(address strategy);

  /**
   * @notice Error emitted when the rebalance is invalid (the from and to strategies are the same or the assets are different)
   */
  error InvalidRebalance();

  /**
   * @notice Error emitted when the revenue sharing is invalid (the sum of the weights is not equal to 10000)
   */
  error InvalidRevenueSharing();

  /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Struct that represents the bounds of the strategy
   * @param lower The lower bound of the strategy (minimum to leave in the strategy)
   * @param upper The upper bound of the strategy (maximum to deposit in the strategy)
   */
  struct Bound {
    uint128 lower;
    uint128 upper;
  }

  /**
   * @notice Struct that represents the revenue sharing of the asset
   * @param recipient The address of the recipient of the revenue
   * @param weight The weight of the revenue sharing
   */
  struct RevenueSharing {
    address recipient;
    uint256 weight;
  }

  uint256 constant BPS_UNIT = 10000;

  /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the strategies registry (StrategiesRegistry)
   */
  address public strategiesRegistry;

  /**
   * @notice The array of the added strategies addresses
   */
  address[] public strategies;

  /**
   * @notice Mapping of the strategies addresses to a validity boolean
   */
  mapping(address => bool) public isStrategy;

  /**
   * @notice Mapping of the strategies addresses to the bounds of the strategy
   */
  mapping(address => IMetaVault.Bound) public strategiesBounds;

  /**
   * @notice Asset address of the strategies
   */
  mapping(address => address) public strategiesAssets;

  /**
   * @notice Revenue sharing of the assets
   */
  mapping(address => IMetaVault.RevenueSharing[]) public assetsRevenueSharings;

  /**
   * @notice Buffer share to keep in the vault for each asset
   */
  mapping(address => uint256) public strategiesAssetsBuffers;

  /**
   * @notice Profit on each asset
   */
  mapping(address => uint256) public profits;

  /**
   * @notice Total owned asset deposited strategies
   */
  mapping(address => uint256) public depositedAssets;

  /**
   * @notice Total owned asset deposited in each strategy
   */
  mapping(address => mapping(address => uint256)) public depositedAssetsByStrategy;

  /**
   * @notice The number of decimals of the stablecoin (to be initialized)
   */
  uint8 public decimalsNumber;

  /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

  function init(
    address _accessControl,
    address _strategiesRegistry,
    address _lzEndpoint,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external initializer {
    _initAAccessControl(_accessControl);
    _transferOwnership(AccessControl(_accessControl).curator());
    address curator = AccessControl(_accessControl).curator();

    decimalsNumber = _decimals;
    strategiesRegistry = _strategiesRegistry;
    __OFT_init(_lzEndpoint, _name, _symbol, curator);
    // TODO add other variables + set isStrategy for each strategy
  }

  /****************************************************
  *                  OFT OVERRIDE                     *
  ****************************************************/

  function decimals() public view override returns (uint8) {
    return decimalsNumber;
  }

  /****************************************************
  *                TELLER FUNCTIONS                   *
  ****************************************************/

  /**
   * @notice Deposit the asset in the vault and mint the stablecoin tokens
   * @param asset The address of the asset to deposit
   * @param mintAmount The amount of stablecoin tokens to mint
   * @param amount The amount of the asset to deposit
   * @param from The address of the depositor
   * @param to The address of the recipient
   */
  function deposit(address asset, uint256 mintAmount, uint256 amount, address from, address to) external onlyTeller  {
    SafeTransferLib.safeTransferFrom(asset, from, address(this), amount);
    _mint(to, mintAmount);
  }

  /**
   * @notice Withdraw the asset from the vault and burn the stablecoin tokens
   * @param asset The address of the asset to withdraw
   * @param burnAmount The amount of stablecoin tokens to burn
   * @param transferAmount The amount of the asset to transfer
   * @param from The address of the withdrawer
   * @param to The address of the recipient
   */
  function withdraw(address asset, uint256 burnAmount,  uint256 transferAmount, address from, address to) external onlyTeller {
    _burn(from, burnAmount);
    SafeTransferLib.safeTransfer(asset, to, transferAmount);
  }

  /****************************************************
  *               OPERATOR FUNCTIONS                  *
  ****************************************************/

  /**
   * @notice Rebalance the assets between the strategies
   * @param from The address of the strategy to remove the asset from (0x0 for the vault)
   * @param to The address of the strategy to deposit the asset to (0x0 for the vault)
   * @param amount The amount of the asset to rebalance (assets amount in case of deposit, shares amount in case of withdraw/rebalance)
   * @return depositedShares The amount of shares deposited in the strategy
   */
  function rebalance(address from, address to, uint256 amount) external onlyOperator returns (uint256 depositedShares) {
    // rebalance logic
    if (from != address(0) &&(!isStrategy[from] || !StrategiesRegistry(strategiesRegistry).isValidStrategy(from))) {
      revert InvalidStrategy(from);
    } else if (to != address(0) && (!isStrategy[to] || !StrategiesRegistry(strategiesRegistry).isValidStrategy(to))) {
      revert InvalidStrategy(to);
    } else if (from == to || (from != address(0) && to != address(0) && strategiesAssets[from] != strategiesAssets[to])) {
      revert InvalidRebalance();
    }
    address asset;

    if (from != address(0)) {
      asset = strategiesAssets[from];
      amount = _removeFromStrategy(from, asset, amount);
    }
    if (to != address(0)) {
      if (asset == address(0)) {
        asset = strategiesAssets[to];
      }
      depositedShares = _depositInStrategy(to, asset, amount);
    }
  }

  /**
   * @notice Deposit the asset in a strategy and ensure the bounds are respected
   * @param strategy The address of the strategy to deposit the asset to
   * @param asset The address of the asset to deposit
   * @param amount The amount of the asset to deposit
   */
  function _depositInStrategy(address strategy, address asset, uint256 amount) internal returns (uint256) {
    _ensureStrategyDepositBounds(strategy, asset, amount);
    depositedAssets[asset] += amount;
    depositedAssetsByStrategy[asset][strategy] += amount;

    Allowance.approveTokenIfNeeded(asset, amount, strategy);
    return ERC4626(strategy).deposit(amount, address(this));
  }

  /**
   * @notice Ensure the bounds of the strategy are respected when depositing the asset
   * @param strategy The address of the strategy to deposit the asset to
   * @param asset The address of the asset to deposit
   * @param addingAmount The amount of the asset to deposit
   */
  function _ensureStrategyDepositBounds(address strategy, address asset, uint256 addingAmount) internal view {
    IMetaVault.Bound memory bounds = strategiesBounds[strategy];
    uint256 totalDepositedStrategy = depositedAssetsByStrategy[asset][strategy];
    uint256 totalDeposited = depositedAssets[asset];
    uint256 selfBalance = ERC20(asset).balanceOf(address(this));
    uint256 newTotalAssets = totalDepositedStrategy + addingAmount;
    uint256 upperBound = bounds.upper * newTotalAssets / BPS_UNIT;
    uint256 bufferBound = (BPS_UNIT - strategiesAssetsBuffers[asset]) * (totalDeposited + selfBalance) / BPS_UNIT;

    if (newTotalAssets > upperBound || newTotalAssets > bufferBound) {
      revert InvalidRebalance();
    }
  }

  /**
   * @notice Remove the asset from a strategy, ensure the bounds are respected and compute the profits
   * @param strategy The address of the strategy to remove the asset from
   * @param asset The address of the asset to remove
   * @param amount The amount of the asset to remove
   * @return ownedRedeemed The amount of owned assets removed from the strategy
   */
  function _removeFromStrategy(address strategy, address asset, uint256 amount) internal returns (uint256) {
    uint256 dec = decimals();
    uint256 sharesBalance = ERC4626(strategy).balanceOf(address(this));
    uint256 totalOwnedAssets = ERC4626(strategy).convertToAssets(sharesBalance);
    uint256 ratio = amount * (10 ** (dec + 10)) / sharesBalance / 10**10;
    uint256 redeemed = ERC4626(strategy).redeem(amount, address(this), address(this));
    uint256 ownedRedeemed = redeemed * ratio / (10 ** dec);


    _ensureStrategyWithdrawBounds(strategy, asset, ownedRedeemed);

    depositedAssets[asset] -= ownedRedeemed;
    profits[asset] += redeemed - ownedRedeemed;

    return ownedRedeemed;
  }

  /**
   * @notice Ensure the bounds of the strategy are respected when withdrawing the asset
   * @param strategy The address of the strategy to withdraw the asset from
   * @param asset The address of the asset to withdraw
   * @param removingAmount The amount of the asset to withdraw
   */
  function _ensureStrategyWithdrawBounds(address strategy, address asset, uint256 removingAmount) internal view {
    IMetaVault.Bound memory bounds = strategiesBounds[strategy];
    uint256 totalDepositedStrategy = depositedAssetsByStrategy[asset][strategy];
    uint256 totalDeposited = depositedAssets[asset];
    uint256 newTotalAssets = totalDepositedStrategy - removingAmount;
    uint256 lowerBound = bounds.lower * totalDeposited / BPS_UNIT;

    if (newTotalAssets < lowerBound) {
      revert InvalidRebalance();
    }
  }

  /**
   * @notice Share profits of the asset with the revenue sharings recipients
   */
  function shareRevenue(address asset) public onlyOperator {
    uint256 len = assetsRevenueSharings[asset].length;
    uint256 revenue = profits[asset];
    for (uint256 i = 0; i < len; i++) {
      IMetaVault.RevenueSharing memory sharing = assetsRevenueSharings[asset][i];
      uint256 amount = revenue * sharing.weight / BPS_UNIT;
      profits[asset] -= amount;
      ERC4626(asset).transfer(sharing.recipient, amount);
    }
  }

  /**
   * @notice Share profits of multiple assets with the revenue sharings recipients
   */
  function shareRevenues(address[] calldata assets) external onlyOperator {
    uint256 len = assets.length;
    for (uint256 i = 0; i < len; i++) {
      shareRevenue(assets[i]);
    }
  }

  /****************************************************
  *                     SETTERS                       *
  ****************************************************/

  /**
   * @notice Set the bounds of the strategy
   * @param strategy The address of the strategy
   * @param lower The lower bound of the strategy
   * @param upper The upper bound of the strategy
   */
  function setStrategyBounds(address strategy, uint128 lower, uint128 upper) external onlyCurator {
    strategiesBounds[strategy] = IMetaVault.Bound(lower, upper);
  }

  /**
   * @notice Set the revenue sharings of the asset
   * @param asset The address of the asset
   * @param newRevenueSharings The new revenue sharings of the asset
   */
  function setRevenueSharings(address asset, IMetaVault.RevenueSharing[] calldata newRevenueSharings) external onlyCurator {
    uint256 weightsSum = 0;

    for (uint256 i = 0; i < newRevenueSharings.length; ++i) {
      weightsSum += newRevenueSharings[i].weight;
    }

    if (weightsSum != BPS_UNIT) {
      revert InvalidRevenueSharing();
    }

    IMetaVault.RevenueSharing[] storage sharings = assetsRevenueSharings[asset];

    // Resize the array to the actual length
    assembly {
      sstore(sharings.slot, newRevenueSharings.length)
    }

    for (uint256 i = 0; i < newRevenueSharings.length; ++i) {
      sharings[i] = newRevenueSharings[i];
    }
  }

  /**
   * @notice Add a strategy to the vault
   * @param strategy The address of the strategy (must be a valid erc4626 vault approved in StrategiesRegistry)
   */
  function addStrategy(address strategy) external onlyCurator {
    if (!StrategiesRegistry(strategiesRegistry).isValidStrategy(strategy)) {
      revert InvalidStrategy(strategy);
    }
    isStrategy[strategy] = true;
    strategiesAssets[strategy] = ERC4626(strategy).asset();
    strategies.push(strategy);
  }

  /**
   * @notice Set the buffer ratio of the asset
   * @param asset The address of the asset
   * @param buffer The buffer ratio of the asset
   */
  function setAssetBuffer(address asset, uint256 buffer) external onlyCurator {
    strategiesAssetsBuffers[asset] = buffer;
  }
}