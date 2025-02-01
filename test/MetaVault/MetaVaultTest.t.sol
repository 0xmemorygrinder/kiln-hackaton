// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.28;

import { MetaVault } from "src/MetaVault.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { ERC4626 } from "solady/tokens/ERC4626.sol";
import { StrategiesRegistry } from "src/StrategiesRegistry.sol";
import "../AccessControl/AccessControlTest.t.sol";
import { IChainlinkOracle } from "../../src/interfaces/IChainlinkOracle.sol";
import { IOFT, SendParam, MessagingFee } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import "forge-std/Test.sol";

contract MetaVaultTest is Test, AccessControlTest {
    StrategiesRegistry strategiesRegistry;
    MetaVault metaVault;
    address constant LZ_MAINNET_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    function setUp() virtual public override {
        super.setUp();

        vm.prank(admin);
        strategiesRegistry = new StrategiesRegistry();

        MetaVault implem = new MetaVault();
        metaVault = MetaVault(deployProxy(address(implem), admin, ""));
        metaVault.init(address(accessControl), LZ_MAINNET_ENDPOINT, "Test", "TST", 18);
        uint256 role = accessControl.OPERATOR_ROLE();
        vm.prank(curator);
        accessControl.grantRoles(operator, role);
    }

    function test_Init_normal() public view virtual override {
        assertEq(metaVault.accessControl(), address(accessControl));
        assertEq(metaVault.decimals(), 18);
        assertEq(metaVault.owner(), curator);
        assertEq(address(metaVault.endpoint()), LZ_MAINNET_ENDPOINT);
        assertEq(metaVault.name(), "Test");
        assertEq(metaVault.symbol(), "TST");
    }

    function test_Deposit_normal() public {
        address asset = USDC;
        uint256 mintAmount = 900000;
        uint256 amount = 1000000;
        address teller = metaVault.getTeller();

        deal(USDC, alice, 1000000);
        vm.prank(alice);
        ERC20(USDC).approve(address(metaVault), amount);

        vm.prank(teller);
        metaVault.deposit(asset, mintAmount, amount, alice, bob);

        assertEq(metaVault.balanceOf(bob), mintAmount);
    }

    function test_Deposit_withoutApprove() public {
        address asset = USDC;
        uint256 mintAmount = 900000;
        uint256 amount = 1000000;
        address teller = metaVault.getTeller();

        deal(USDC, alice, 1000000);

        vm.expectRevert();
        vm.prank(teller);
        metaVault.deposit(asset, mintAmount, amount, alice, bob);
    }

    function test_Burn_normal() public {
        address asset = USDC;
        uint256 amount = 1000000;
        uint256 burnAmount = 900000;
        address teller = metaVault.getTeller();

        deal(address(metaVault), alice, 1000000);
        deal(USDC, address(metaVault), 1000000);

        vm.prank(teller);
        metaVault.withdraw(asset, amount, burnAmount, alice, bob);

        assertEq(ERC20(USDC).balanceOf(bob), burnAmount);
    }

    function test_Bridge_normal() public {
        address asset = USDC;
        uint256 mintAmount = 900000;
        uint256 amount = 1000000;
        address teller = metaVault.getTeller();

        deal(USDC, alice, 1000000);
        vm.prank(alice);
        ERC20(USDC).approve(address(metaVault), amount);

        vm.prank(curator);
        metaVault.setPeer(30110, bytes32(bytes20(uint160(makeAddr("oft receiver")))));

        vm.prank(teller);
        metaVault.deposit(asset, mintAmount, amount, alice, bob);

        SendParam memory sendParam;
        sendParam.dstEid = 30110; // arbitrum
        sendParam.amountLD = 900000;
        sendParam.minAmountLD = 0;
        sendParam.extraOptions = hex"0003010011010000000000000000000000000000ea60";
        MessagingFee memory fee = IOFT(metaVault).quoteSend(sendParam, false);

        deal(alice, fee.nativeFee);
        vm.prank(alice);
        metaVault.send{ value: fee.nativeFee }(sendParam, fee, alice);
    }

    function test_Rebalance_firstStrategy() public {
        uint256 amount = 1000000;
        uint128 minBound = 100; // 1%
        uint128 maxBound = 10000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);

        vm.prank(operator);
        metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);

        assertEq(metaVault.depositedAssets(USDC), amount);
        assertEq(ERC20(USDC).balanceOf(address(metaVault)), 0);
    }

    function test_Rebalance_depositAboveUpperBound() public {
        uint256 amount = 1000000;
        uint128 minBound = 100; // 1%
        uint128 maxBound = 9000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);

        vm.expectRevert();
        vm.prank(operator);
        metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);
    }

    function test_Rebalance_depositAboveMinimumBuffer() public {
        uint256 amount = 1000000;
        uint128 minBound = 100; // 1%
        uint128 maxBound = 10000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);
        vm.prank(curator);
        metaVault.setAssetBuffer(USDC, 1000); // 10% buffer

        vm.expectRevert();
        vm.prank(operator);
        metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);
    }

    function test_Rebalance_removeFromStrategy() public {
        uint256 amount = 1000000;
        uint128 minBound = 0; // 0%
        uint128 maxBound = 10000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);

        vm.prank(operator);
        uint256 depositedShares = metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);

        vm.prank(operator);
        metaVault.rebalance(AAVE_VAULT_USDC, address(0), depositedShares);

        assertEq(metaVault.depositedAssets(AAVE_VAULT_USDC), 0);
        assertApproxEqRel(ERC20(USDC).balanceOf(address(metaVault)), amount, 1e15);
    }

    function test_Rebalance_withdrawBelowLowerBound() public {
        uint256 amount = 1000000;
        uint128 minBound = 1000; // 10%
        uint128 maxBound = 10000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);

        vm.prank(operator);
        uint256 depositedShares = metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);

        vm.expectRevert();
        vm.prank(operator);
        metaVault.rebalance(AAVE_VAULT_USDC, address(0), depositedShares);
    }

    function test_Rebalance_betweenStrategies() public {
        uint256 amount = 1000000;
        uint128 minBound = 0; // 0%
        uint128 maxBound = 10000; // 100%

        deal(USDC, address(metaVault), amount);

        _addStrategy(AAVE_VAULT_USDC, minBound, maxBound);
        _addStrategy(MORPHO_VAULT_USDC, minBound, maxBound);

        vm.prank(operator);
        uint256 depositedShares = metaVault.rebalance(address(0), AAVE_VAULT_USDC, amount);

        vm.prank(operator);
        metaVault.rebalance(AAVE_VAULT_USDC, MORPHO_VAULT_USDC, depositedShares);

        assertEq(metaVault.depositedAssets(AAVE_VAULT_USDC), 0);
        uint256 shares = ERC4626(MORPHO_VAULT_USDC).balanceOf(address(metaVault));
        assertApproxEqRel(ERC4626(MORPHO_VAULT_USDC).convertToAssets(shares), amount, 1e15);
    }

    function _addStrategy(address strategy, uint128 minBound, uint128 maxBound) internal {
        vm.prank(admin);
        strategiesRegistry.setStrategyStatus(strategy, true);
        vm.startPrank(curator);
        metaVault.addStrategy(strategy);
        metaVault.setStrategyBounds(strategy, minBound, maxBound); 
        vm.stopPrank();
    }
}
