// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.28;

import { Accountant } from "../../src/Accountant.sol";
import "../MetaVault/MetaVaultTest.t.sol";
import { IChainlinkOracle } from "../../src/interfaces/IChainlinkOracle.sol";
import "forge-std/Test.sol";

contract AccountantTest is Test, MetaVaultTest {
    Accountant accountant;

    function setUp() public override {
        super.setUp();

        Accountant implem = new Accountant();
        accountant = Accountant(deployProxy(address(implem), admin, ""));
        accountant.init(address(accessControl));
    }

    function test_Init_normal() public view override {
        assertEq(accountant.accessControl(), address(accessControl));
    }

    function test_AddCollateral_Normal() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        assertEq(accountant.isCollateral(USDC), true);
        assertEq(accountant.collateralOracles(USDC), USDC_ORACLE);
        (uint256 burnFee, uint256 mintFee, uint256 burnBound, uint256 mintBound) =
            accountant.collateralsParameters(USDC);
        assertEq(burnFee, 100);
        assertEq(mintFee, 100);
        assertEq(burnBound, 1000);
        assertEq(mintBound, 8000);
    }

    function test_AddCollateral_Revert() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.startPrank(curator);

        vm.expectRevert(WrongCollateral.selector);
        accountant.addCollateral(address(0), USDC_ORACLE, 100, 100, 1000, 8000);

        vm.expectRevert(WrongOracle.selector);
        accountant.addCollateral(USDC, address(0), 100, 100, 1000, 8000);

        vm.expectRevert(WrongFee.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 10_001, 100, 1000, 8000);

        vm.expectRevert(WrongFee.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 10_001, 1000, 8000);

        vm.expectRevert(WrongBound.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 10_001, 8000);

        vm.expectRevert(WrongBound.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 10_001);

        vm.expectRevert(WrongBound.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1001, 1000);

        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);
        vm.expectRevert(CollateralAlreadyExists.selector);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.stopPrank();
    }

    function test_RemoveCollateral_Normal() public {
        vm.startPrank(curator);

        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);
        assertEq(accountant.isCollateral(USDC), true);

        accountant.removeCollateral(USDC);
        assertEq(accountant.isCollateral(USDC), false);
        assertEq(accountant.collateralOracles(USDC), address(0));
        (uint256 burnFee, uint256 mintFee, uint256 burnBound, uint256 mintBound) =
            accountant.collateralsParameters(USDC);
        assertEq(burnFee, 0);
        assertEq(mintFee, 0);
        assertEq(burnBound, 0);
        assertEq(mintBound, 0);

        vm.stopPrank();
    }

    function test_RemoveCollateral_Revert() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        accountant.removeCollateral(USDC);

        vm.startPrank(curator);

        vm.expectRevert(CollateralDoesNotExist.selector);
        accountant.removeCollateral(USDT);

        vm.stopPrank();
    }

    function test_SetCollateralOracle_Normal() public {
        vm.startPrank(curator);

        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);
        assertEq(accountant.collateralOracles(USDC), USDC_ORACLE);

        accountant.setCollateralOracle(USDC, USDT_ORACLE);
        assertEq(accountant.collateralOracles(USDC), USDT_ORACLE);

        vm.stopPrank();
    }

    function test_SetCollateralOracle_Revert() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        accountant.setCollateralOracle(USDC, USDT_ORACLE);

        vm.startPrank(curator);

        vm.expectRevert(CollateralDoesNotExist.selector);
        accountant.setCollateralOracle(USDT, USDT_ORACLE);

        vm.stopPrank();
    }

    function test_SetCollateralParameters_Normal() public {
        vm.startPrank(curator);

        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        accountant.setCollateralsParameters(USDC, 200, 200, 2000, 10_000);
        (uint256 burnFee, uint256 mintFee, uint256 burnBound, uint256 mintBound) =
            accountant.collateralsParameters(USDC);
        assertEq(burnFee, 200);
        assertEq(mintFee, 200);
        assertEq(burnBound, 2000);
        assertEq(mintBound, 10_000);

        vm.stopPrank();
    }

    function test_SetCollateralParameters_Revert() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        accountant.setCollateralsParameters(USDC, 200, 200, 2000, 10_000);

        vm.startPrank(curator);

        vm.expectRevert(CollateralDoesNotExist.selector);
        accountant.setCollateralsParameters(USDT, 200, 200, 2000, 10_000);

        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);
        vm.expectRevert(WrongFee.selector);
        accountant.setCollateralsParameters(USDC, 10_001, 200, 2000, 10_000);

        vm.expectRevert(WrongFee.selector);
        accountant.setCollateralsParameters(USDC, 200, 10_001, 2000, 10_000);

        vm.expectRevert(WrongBound.selector);
        accountant.setCollateralsParameters(USDC, 200, 200, 10_001, 10_000);

        vm.expectRevert(WrongBound.selector);
        accountant.setCollateralsParameters(USDC, 200, 200, 2000, 10_001);

        vm.expectRevert(WrongBound.selector);
        accountant.setCollateralsParameters(USDC, 200, 200, 2001, 2000);

        vm.stopPrank();
    }

    function test_GetMintRate_Normal() public {
        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        uint256 latestAnswer = uint256(IChainlinkOracle(USDC_ORACLE).latestAnswer());

        assertEq(accountant.getMintRate(USDC), latestAnswer * 1e10);

        vm.prank(TELLER);
        assertEq(accountant.mint(USDC, 1e6), latestAnswer * 1e10);

        assertEq(accountant.totalMinted(), latestAnswer * 1e10);
        assertEq(accountant.collateralsMinted(USDC), latestAnswer * 1e10);
    }

    function test_GetMintRate_BoundReached() public {
        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));
        vm.prank(TELLER);
        accountant.mint(USDC, 1e6);

        uint256 latestAnswer = uint256(IChainlinkOracle(USDC_ORACLE).latestAnswer());

        assertEq(accountant.getMintRate(USDC), (latestAnswer * 1e10) * 9900 / 10000);

        vm.prank(TELLER);
        assertEq(accountant.mint(USDC, 1e6), (latestAnswer * 1e10) * 9900 / 10000);
    }

    function test_GetBurnRate_Positive() public {
        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));

        vm.prank(TELLER);
        accountant.mint(USDC, 1e6);

        assertEq(accountant.getBurnRate(USDC), 1e6);

        vm.prank(TELLER);
        assertEq(accountant.burn(USDC, 1e18), 1e6);
    }

    function test_GetBurnRate_Negative() public {
        vm.prank(curator);
        accountant.addCollateral(USDC, USDC_ORACLE, 100, 100, 1000, 8000);

        vm.mockCall(address(accessControl), AccessControl.getMetaVault.selector, abi.encode(metaVault));

        vm.mockCall(USDC_ORACLE, IChainlinkOracle.latestAnswer.selector, abi.encode(0.99e8));

        vm.prank(TELLER);
        accountant.mint(USDC, 1e6);

        assertEq(accountant.getBurnRate(USDC), 1e6);

        vm.prank(TELLER);
        assertEq(accountant.burn(USDC, 1e18), 1e6);

        assertEq(accountant.totalMinted(), 0);
        assertEq(accountant.collateralsMinted(USDC), 0);
    }
}
