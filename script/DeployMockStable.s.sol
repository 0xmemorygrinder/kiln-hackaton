// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import { Factory } from "../src/Factory.sol";
import { Accountant } from "../src/Accountant.sol";
import { MetaVault } from "../src/MetaVault.sol";
import { AccessControl } from "../src/AccessControl.sol";

contract DeployMockStable is Script {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant AAVE_VAULT_USDC = 0x2db0B0fa84C3c8B342183FD0B777C521ec054325;
    address constant MORPHO_VAULT_USDC = 0x50913b45F278c39c8A7925b3C31DD88B95fb1AA2;
    address constant AAVE_VAULT_USDT = 0x924e38bdFDa04990Fc78FEc258E8B83B3478B1Af;
    address constant MORPHO_VAULT_USDT = 0x75e4cE661A49B6bfb2d5b1a8231E32aB47F8b706;
    address constant USDC_ORACLE = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant USDT_ORACLE = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address constant FACTORY = 0xA343B1FC2897b8C49A72A9A0B2675cB9c7664e8c;
    address constant ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        Factory factory = Factory(FACTORY);
        console.log("Deploying stablecoin", address(factory));

        vm.recordLogs();
        factory.deployStablecoin(deployer, deployer, Factory.MetaVaultArguments(ENDPOINT, "CryptoForge USD", "CFUSD", 18));
        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        VmSafe.Log memory lastLog = logs[logs.length - 1];
        (address accountant, address teller, address metaVault, address staking, address accessControl) = abi.decode(lastLog.data, (address, address, address, address, address));

        console.log("Accountant", accountant);
        console.log("Teller", teller);
        console.log("MetaVault", metaVault);
        console.log("AccessControl", accessControl);

        Accountant(accountant).addCollateral(USDC, USDC_ORACLE, 0, 0, 0, 10000);
        Accountant(accountant).addCollateral(USDT, USDT_ORACLE, 0, 0, 0, 10000);

        MetaVault(metaVault).addStrategy(AAVE_VAULT_USDC);
        MetaVault(metaVault).setStrategyBounds(AAVE_VAULT_USDC, 0, 10000);
        MetaVault(metaVault).addStrategy(MORPHO_VAULT_USDC);
        MetaVault(metaVault).setStrategyBounds(MORPHO_VAULT_USDC, 0, 10000);
        MetaVault(metaVault).addStrategy(AAVE_VAULT_USDT);
        MetaVault(metaVault).setStrategyBounds(AAVE_VAULT_USDT, 0, 10000);
        MetaVault(metaVault).addStrategy(MORPHO_VAULT_USDT);
        MetaVault(metaVault).setStrategyBounds(MORPHO_VAULT_USDT, 0, 10000);

        MetaVault(metaVault).setAssetBuffer(USDC, 1000);
        MetaVault(metaVault).setAssetBuffer(USDT, 1000);

        vm.stopBroadcast();
    }
}