// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.28;

import { AccessControl } from "../../src/AccessControl.sol";
import "../MainnetTest.t.sol";
import "forge-std/Test.sol";

contract AccessControlTest is Test, MainnetTest {
    AccessControl accessControl;

    address METAVAULT = makeAddr("METAVAULT");
    address STAKER = makeAddr("STAKER");
    address TELLER = makeAddr("TELLER");
    address ACCOUNTANT = makeAddr("ACCOUNTANT");
    address TREASURY = makeAddr("TREASURY");

    function setUp() public virtual override {
        super.setUp();

        AccessControl implem = new AccessControl();
        accessControl = AccessControl(deployProxy(address(implem), admin, ""));
        accessControl.init(METAVAULT, STAKER, TELLER, ACCOUNTANT, curator, TREASURY);
    }

    function test_Init_normal() public view virtual {
        assertEq(accessControl.metaVault(), METAVAULT);
        assertEq(accessControl.staker(), STAKER);
        assertEq(accessControl.teller(), TELLER);
        assertEq(accessControl.accountant(), ACCOUNTANT);
        assertEq(accessControl.curator(), curator);
        assertEq(accessControl.treasury(), TREASURY);
        assertEq(accessControl.owner(), curator);
    }

    function test_GrantRoleOperator() public {
        uint256 operatorRole = accessControl.OPERATOR_ROLE();
        vm.prank(curator);
        accessControl.grantRoles(alice, operatorRole);
        assertTrue(accessControl.isOperator(alice));
    }

    function test_IsCurator() public view {
        assertTrue(accessControl.isCurator(curator));
        assertFalse(accessControl.isCurator(alice));
    }

    function test_IsTreasury() public view {
        assertTrue(accessControl.isTreasury(TREASURY));
        assertFalse(accessControl.isTreasury(alice));
    }

    function test_IsMetaVault() public view {
        assertTrue(accessControl.isMetaVault(METAVAULT));
        assertFalse(accessControl.isMetaVault(alice));
    }

    function test_SetTreasury() public {
        vm.prank(curator);
        accessControl.setTreasury(alice);
        assertEq(accessControl.treasury(), alice);
    }

    function test_SetCurator() public {
        vm.prank(curator);
        accessControl.setCurator(alice);
        assertEq(accessControl.curator(), alice);
        assertEq(accessControl.owner(), alice);
    }
}
