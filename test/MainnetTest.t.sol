// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "./BaseTest.t.sol";

contract MainnetTest is BaseTest {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant AAVE_VAULT_USDC = 0x2db0B0fa84C3c8B342183FD0B777C521ec054325;
    address constant MORPHO_VAULT_USDC = 0x50913b45F278c39c8A7925b3C31DD88B95fb1AA2;
    address constant AAVE_VAULT_USDT = 0x924e38bdFDa04990Fc78FEc258E8B83B3478B1Af;
    address constant MORPHO_VAULT_USDT = 0x75e4cE661A49B6bfb2d5b1a8231E32aB47F8b706;
    address constant USDC_ORACLE = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant USDT_ORACLE = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    function setUp() public virtual {
        // Add known labels here
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(AAVE_VAULT_USDC, "AAVE_VAULT_USDC");
        vm.label(MORPHO_VAULT_USDC, "MORPHO_VAULT_USDC");
        vm.label(AAVE_VAULT_USDT, "AAVE_VAULT_USDT");
        vm.label(MORPHO_VAULT_USDT, "MORPHO_VAULT_USDT");
        vm.label(USDC_ORACLE, "USDC_ORACLE");
        vm.label(USDT_ORACLE, "USDT_ORACLE");

        fork();
    }

    function fork() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 21752040); // Change the block number if needed
    }

    function fork(uint256 blockNumber) public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), blockNumber);
    }
}
