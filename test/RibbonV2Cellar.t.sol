// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {Test, console, stdStorage, StdStorage} from "@forge-std/Test.sol";
import {IRibbonThetaVault} from "src/interfaces/IRibbonThetaVault.sol";

contract RibbonV2Cellar is Test {
    using stdStorage for StdStorage;

    // =================== All mock addresses from mainnet ===================

    // Ribbon Finance: ETH Covered Call V2
    IRibbonThetaVault public constant ribbon_eth_call_vault = IRibbonThetaVault(0x25751853Eab4D0eB3652B5eB6ecB102A2789644B);

    // =================== Variables ===================

    // Cellar
    RibbonV2Cellar public cellar;

    function setUp() external {

    // cellar = new RibbonV2Cellar();

    }
}