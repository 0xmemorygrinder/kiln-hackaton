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

contract MetaVault is IMetaVault, OFTUpgradeable, AAccessControl {
  error Unauthorized();
  error InvalidStrategy(address strategy);
  error InvalidRebalance();
  error InvalidRevenueSharing();

  uint256 constant BPS_UNIT = 10000;
  address public constant STRATEGIES_REGISTRY = 0x3Ede3eCa2a72B3aeCC820E955B36f38437D01395;

  address[] public strategies;
  mapping(address => bool) public isStrategy;
  mapping(address => IMetaVault.Bound) public strategiesBounds;
  mapping(address => address) public strategiesAssets;
  uint256 public strategiesBoundDefault;
  mapping(address => IMetaVault.RevenueSharing[]) public assetsRevenueSharings;
  mapping(address => uint256) public strategiesAssetsBuffers;
  mapping(address => uint256) public profits;
  mapping(address => uint256) public depositedAssets;
  mapping(address => mapping(address => uint256)) public depositedAssetsByStrategy;
  bool public mintAllowed;
  uint8 public decimalsNumber;

  function init(
    address _accessControl,
    address _lzEndpoint,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external initializer {
    _initAAccessControl(_accessControl);
    _transferOwnership(AccessControl(_accessControl).curator());
    address curator = AccessControl(_accessControl).curator();

    decimalsNumber = _decimals;
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
  function deposit(address asset, uint256 mintAmount, uint256 amount, address from, address to) external override onlyTeller  {
    SafeTransferLib.safeTransferFrom(asset, from, address(this), amount);
    _mint(to, mintAmount);
  }

  function withdraw(address asset, uint256 burnAmount,  uint256 transferAmount, address from, address to) external override onlyTeller {
    _burn(from, burnAmount);
    SafeTransferLib.safeTransfer(asset, to, transferAmount);
  }

  /****************************************************
  *               OPERATOR FUNCTIONS                  *
  ****************************************************/

  function rebalance(address from, address to, uint256 amount) external onlyOperator returns (uint256 depositedShares) {
    // rebalance logic
    if (from != address(0) &&(!isStrategy[from] || !StrategiesRegistry(STRATEGIES_REGISTRY).isValidStrategy(from))) {
      revert InvalidStrategy(from);
    } else if (to != address(0) && (!isStrategy[to] || !StrategiesRegistry(STRATEGIES_REGISTRY).isValidStrategy(to))) {
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

  function _depositInStrategy(address strategy, address asset, uint256 amount) internal returns (uint256) {
    _ensureStrategyDepositBounds(strategy, asset, amount);
    depositedAssets[asset] += amount;
    depositedAssetsByStrategy[asset][strategy] += amount;

    Allowance.approveTokenIfNeeded(asset, amount, strategy);
    return ERC4626(strategy).deposit(amount, address(this));
  }

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

  function _removeFromStrategy(address strategy, address asset, uint256 amount) internal returns (uint256) {
    uint256 dec = decimals();
    uint256 sharesBalance = ERC4626(strategy).balanceOf(address(this));
    uint256 totalOwnedAssets = ERC4626(strategy).convertToAssets(sharesBalance);
    uint256 ratio = amount * (10 ** (dec + 10)) / sharesBalance / 10**10;
    uint256 redeemed = ERC4626(strategy).redeem(amount, address(this), address(this));
    uint256 ownedRedeemed = redeemed * ratio / (10 ** dec);


    _ensureStrategyWithdrawBounds(strategy, asset, ownedRedeemed);

      depositedAssets[asset] -= ownedRedeemed;
    profits[strategy] += redeemed - ownedRedeemed;

    return ownedRedeemed;
  }

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

  function shareRevenues(address[] calldata assets) external onlyOperator {
    uint256 len = assets.length;
    for (uint256 i = 0; i < len; i++) {
      shareRevenue(assets[i]);
    }
  }

  /****************************************************
  *                     SETTERS                       *
  ****************************************************/

  function setStrategyBounds(address strategy, uint128 lower, uint128 upper) external onlyCurator {
    strategiesBounds[strategy] = IMetaVault.Bound(lower, upper);
  }

  function setStrategiesBoundDefault(uint256 bound) external onlyCurator {
    strategiesBoundDefault = bound;
  }

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

  function addStrategy(address strategy) external onlyCurator {
    if (!StrategiesRegistry(STRATEGIES_REGISTRY).isValidStrategy(strategy)) {
      revert InvalidStrategy(strategy);
    }
    isStrategy[strategy] = true;
    strategiesAssets[strategy] = ERC4626(strategy).asset();
    strategies.push(strategy);
  }

  function setMintAllowed(bool allowed) external onlyOwner {
    mintAllowed = allowed;
  }

  function setAssetBuffer(address asset, uint256 buffer) external onlyCurator {
    strategiesAssetsBuffers[asset] = buffer;
  }
}