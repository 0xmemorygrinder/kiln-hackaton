// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Initializable } from "solady/utils/Initializable.sol";
import { ERC4626 } from "solady/tokens/ERC4626.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { OFTUpgradeable } from "./lib/lz-oft-upgradeable/OFTUpgradeable.sol";
import { IMetaVault } from "./interfaces/IMetaVault.sol";
import { AAccessControl } from "./utils/AAccessControl.sol";

contract MetaVault is IMetaVault, OFTUpgradeable, AAccessControl {
  error Unauthorized();
  error InvalidStrategy(address strategy);
  error InvalidRebalance();
  error InvalidRevenueSharing();

  uint256 constant BPS_UNIT = 10000;

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
    __OFT_init(_lzEndpoint, _name, _symbol, owner());
    _initAAccessControl(_accessControl);
    decimalsNumber = _decimals;
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
  function deposit(address asset, uint256 amount, address from, address to) external override onlyTeller  {
    SafeTransferLib.safeTransferFrom(asset, from, address(this), amount);
    _mint(to, amount);
  }

  function withdraw(address asset, uint256 amount, address from, address to) external override onlyTeller {
    SafeTransferLib.safeTransfer(asset, to, amount);
    _burn(from, amount);
  }

  /****************************************************
  *               OPERATOR FUNCTIONS                  *
  ****************************************************/

  function rebalance(address from, address to, uint256 amount) external onlyOperator {
    // rebalance logic
    if (!isStrategy[from] && from != address(0)) {
      revert InvalidStrategy(from);
    } else if (!isStrategy[to] && to != address(0)) {
      revert InvalidStrategy(to);
    } else if (from == to || strategiesAssets[from] != strategiesAssets[to]) {
      revert InvalidRebalance();
    }
    address asset = strategiesAssets[from];

    if (from != address(0)) {
      _removeFromStrategy(from, asset, amount);
    }
    if (to != address(0)) {
      _depositInStrategy(to, asset, amount);
    }
  }

  function _depositInStrategy(address strategy, address asset, uint256 amount) internal {
    _ensureStrategyDepositBounds(strategy, asset, amount);
    depositedAssets[strategy] += amount;
    ERC4626(strategy).deposit(amount, address(this));
  }

  function _ensureStrategyDepositBounds(address strategy, address asset, uint256 addingAmount) internal view {
    IMetaVault.Bound memory bounds = strategiesBounds[strategy];
    uint256 totalDepositedStrategy = depositedAssetsByStrategy[asset][strategy];
    uint256 totalDeposited = depositedAssets[asset];
    uint256 selfBalance = ERC20(asset).balanceOf(address(this));
    uint256 newTotalAssets = totalDepositedStrategy + addingAmount;
    uint256 upperBound = bounds.upper * totalDeposited / BPS_UNIT;
    uint256 bufferBound = (BPS_UNIT - strategiesAssetsBuffers[asset]) * (totalDeposited + selfBalance) / BPS_UNIT;

    if (newTotalAssets > upperBound || newTotalAssets > bufferBound) {
      revert InvalidRebalance();
    }
  }

  function _removeFromStrategy(address strategy, address asset, uint256 amount) internal returns (uint256) {
    uint256 dec = decimals();
    uint256 sharesBalance = ERC4626(strategy).balanceOf(address(this));
    uint256 totalOwnedAssets = ERC4626(strategy).convertToAssets(sharesBalance);
    uint256 ratio = amount * (10 ** dec) / totalOwnedAssets;
    uint256 redeemed = ERC4626(strategy).redeem(amount, address(this), address(this));
    uint256 ownedRedeemed = redeemed * ratio / (10 ** dec);
    depositedAssets[strategy] -= ownedRedeemed;
    profits[strategy] += redeemed - ownedRedeemed;

    _ensureStrategyWithdrawBounds(strategy, asset, ownedRedeemed);

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

  function setStrategyBounds(address strategy, uint128 lower, uint128 upper) external onlyOwner {
    strategiesBounds[strategy] = IMetaVault.Bound(lower, upper);
  }

  function setStrategiesBoundDefault(uint256 bound) external onlyOwner {
    strategiesBoundDefault = bound;
  }

  function setRevenueSharings(address asset, IMetaVault.RevenueSharing[] calldata newRevenueSharings) external onlyOwner {
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

  function setMintAllowed(bool allowed) external onlyOwner {
    mintAllowed = allowed;
  }

  function setAssetBuffer(address asset, uint256 buffer) external onlyOwner {
    strategiesAssetsBuffers[asset] = buffer;
  }
}