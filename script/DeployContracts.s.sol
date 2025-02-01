// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import { StrategiesRegistry } from "../src/StrategiesRegistry.sol";
import { Factory } from "../src/Factory.sol";
import { Accountant } from "../src/Accountant.sol";
import { AccessControl } from "../src/AccessControl.sol";
import { MetaVault } from "../src/MetaVault.sol";
import { Staking } from "../src/Staking.sol";
import { Teller } from "../src/Teller.sol";

contract DeployContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        StrategiesRegistry strategiesRegistry = new StrategiesRegistry();
        Factory factory = new Factory(deployer);

        Accountant accountant = new Accountant();
        MetaVault metaVault = new MetaVault();
        Staking staking = new Staking();
        Teller teller = new Teller();
        AccessControl accessControl = new AccessControl();

        factory.setStablecoinImplementationAddresses(Factory.StablecoinAddresses(
            address(accountant),
            address(teller),
            address(metaVault),
            address(staking),
            address(accessControl),
            address(strategiesRegistry)
        ));

        address[] memory _strategies = new address[](22);
        _strategies[0] = 0x15BEFDB812690D02eCB4cDE372f42BF0A8c24d68;
        _strategies[1] = 0x924e38bdFDa04990Fc78FEc258E8B83B3478B1Af;
        _strategies[2] = 0x2db0B0fa84C3c8B342183FD0B777C521ec054325;
        _strategies[3] = 0xe2F86504C610EdbaE7A788b04785395fDe781577;
        _strategies[4] = 0x6504158a43208150E5dbc0602d3F3Ac694e0158e;
        _strategies[5] = 0x815d9e5A6F9c9662b07570c801131e8942587132;
        _strategies[6] = 0xB59f4f16709Aa88e04B0addf15a3DF6Aa8B14524;
        _strategies[7] = 0x50913b45F278c39c8A7925b3C31DD88B95fb1AA2;
        _strategies[8] = 0xF4918Ef824a242602E0d3e5DB07fFd4DaC4ad3Ea;
        _strategies[9] = 0x4bf3499072103e9A4afC2Ce4ea09afccF163CD87;
        _strategies[10] = 0xBd01d20e6897e4A148BafFCfa9ED7aA1ac05a4B0;
        _strategies[11] = 0x75e4cE661A49B6bfb2d5b1a8231E32aB47F8b706;
        _strategies[12] = 0x9c4E4c15D0532204186ef757b246253A65B4562D;
        _strategies[13] = 0x75eE9f7aA08d20788898103f28F640FFF0fB85fC;
        _strategies[14] = 0x67c18866E6F6bEE1e9B6d0BB9055a65Dba8E9348;
        _strategies[15] = 0xd972f93d3F8A1B0ae072Cd21CcBb6344f3407275;
        _strategies[16] = 0xc81aB5DE4871a447f1003B90c7Ff8C961702EEb2;
        _strategies[17] = 0x2Df453aA9ac59Dc05030979CA67Af4BBff424333;
        _strategies[18] = 0xe7Bf38c635426caaCfa95966c4C6064e7637fE0A;
        _strategies[19] = 0x804EE40b227B9003BB7bf2880cF502466544F208;
        _strategies[20] = 0x6C310b55D6728423B3bddB9D07A6c21Bb6eFBDCb;
        _strategies[21] = 0x2a7822d6764dFc7a945A4c38776624cB542b32f6;
        strategiesRegistry.setStrategiesStatus(_strategies, true);

        vm.stopBroadcast();
    }
}