// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {Test, console, stdStorage, StdStorage} from "@forge-std/Test.sol";
import {IRibbonThetaVault} from "src/interfaces/IRibbonThetaVault.sol";
import {RibbonV2Cellar} from "src/RibbonV2Cellar.sol";

contract RibbonV2CellarTest is Test {
    using stdStorage for StdStorage;

    // =================== All mock addresses from mainnet ===================

    // Ribbon Finance: ETH Covered Call V2
    IRibbonThetaVault public constant ribbonEthCallVault =
        IRibbonThetaVault(0x25751853Eab4D0eB3652B5eB6ecB102A2789644B);

    // =================== Variables ===================

    // Cellar
    RibbonV2Cellar public cellar;

    // Test accounts
    address public alice = vm.addr(1);
    address public bob = vm.addr(2);

    function setUp() external {
        cellar = new RibbonV2Cellar(ribbonEthCallVault);

        vm.deal(alice, 10 ether);
    }

    function testDeposit() external {
        // Send from alice account
        vm.prank(alice);
        cellar.deposit{value: 1 ether}();
    }
}
