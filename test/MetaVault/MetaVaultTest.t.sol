// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.28;

import { MetaVault } from "src/MetaVault.sol";
import "../AccessControl/AccessControlTest.t.sol";
import { IChainlinkOracle } from "../../src/interfaces/IChainlinkOracle.sol";
import "forge-std/Test.sol";

contract MetaVaultTest is Test, AccessControlTest {
    MetaVault metaVault;
    address constant LZ_MAINNET_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    function setUp() public override {
        super.setUp();

        MetaVault implem = new MetaVault();
        metaVault = MetaVault(deployProxy(address(implem), admin, ""));
        metaVault.init(address(accessControl), LZ_MAINNET_ENDPOINT, "Test", "TST", 18);
    }

    function test_Init_normal() public view override {
        assertEq(metaVault.accessControl(), address(accessControl));
    }
}
