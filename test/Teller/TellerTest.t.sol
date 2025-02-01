// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.28;

import { MetaVault } from "src/MetaVault.sol";
import { Teller } from "src/Teller.sol";
import { Accountant } from "src/Accountant.sol";
import { AccessControl } from "src/AccessControl.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { MetaVaultTest } from "test/MetaVault/MetaVaultTest.t.sol";
import { StrategiesRegistry } from "src/StrategiesRegistry.sol";
import "../AccessControl/AccessControlTest.t.sol";
import { IChainlinkOracle } from "../../src/interfaces/IChainlinkOracle.sol";
import { IOFT, SendParam, MessagingFee } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import "forge-std/Test.sol";

contract TellerTest is Test, MetaVaultTest {
    Teller teller;
    Accountant accountant;

    function setUp() virtual public override {
        super.setUp();

        vm.prank(admin);

        Teller implem = new Teller();
        teller = Teller(deployProxy(address(implem), admin, ""));
        teller.init(address(accessControl));
        vm.label(address(teller), "teller proxy");
        accountant = new Accountant();
        accountant.init(address(accessControl));
    }

    function test_Init_normal() public view virtual override {
        assertEq(teller.accessControl(), address(accessControl));
    }

    function test_TellerDeposit_normal() public {
        address asset = USDC;
        uint256 amount = 1000000;

        deal(USDC, alice, 1000000);
        vm.prank(alice);
        ERC20(USDC).approve(address(metaVault), amount);

        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getAccountant.selector, abi.encode(accountant));
        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        vm.mockCall(address(accessControl), AccessControl.isTeller.selector, abi.encode(true));

        vm.prank(alice);
        teller.deposit(asset, amount, alice);

        assertApproxEqRel(MetaVault(accessControl.getMetaVault()).balanceOf(alice), 1e18, 1e15);
    }

    function test_TellerDeposit_withoutApprove() public {
        address asset = USDC;
        uint256 amount = 1000000;

        deal(USDC, alice, 1000000);

        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getAccountant.selector, abi.encode(accountant));
        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        vm.mockCall(address(accessControl), AccessControl.isTeller.selector, abi.encode(true));

        vm.expectRevert();
        vm.prank(alice);
        teller.deposit(asset, amount, alice);
    }

    function test_TellerWitdraw_normal() public {
        address asset = USDC;
        uint256 amount = 1000000;

        deal(address(metaVault), alice, 1e18);
        deal(USDC, address(metaVault), 1000000);

        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getAccountant.selector, abi.encode(accountant));
        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        vm.mockCall(address(accessControl), AccessControl.isTeller.selector, abi.encode(true));

        vm.prank(alice);
        teller.withdraw(asset, 1e18, alice);

        assertApproxEqRel(ERC20(USDC).balanceOf(alice), amount, 1e15);
    }

    function test_DepositAndBridge_normal() public {
        address asset = USDC;
        uint256 amount = 1000000;

        deal(USDC, alice, 1000000);
        vm.prank(alice);
        ERC20(USDC).approve(address(metaVault), amount);

        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);


        vm.prank(curator);
        metaVault.setPeer(30110, bytes32(bytes20(uint160(makeAddr("oft receiver")))));

        SendParam memory sendParam;
        sendParam.dstEid = 30110; // arbitrum
        sendParam.amountLD = 900000;
        sendParam.minAmountLD = 0;
        sendParam.extraOptions = hex"0003010011010000000000000000000000000000ea60";
        MessagingFee memory fee = IOFT(metaVault).quoteSend(sendParam, false);

        vm.mockCall(address(accessControl), AccessControl.getAccountant.selector, abi.encode(accountant));
        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        vm.mockCall(address(accessControl), AccessControl.isTeller.selector, abi.encode(true));

        deal(alice, fee.nativeFee);
        vm.prank(alice);
        teller.depositAndBridge{value: fee.nativeFee }(asset, amount, alice, sendParam, fee);
    }
}
