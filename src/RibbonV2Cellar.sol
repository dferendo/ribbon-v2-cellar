// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {Multicall} from "./base/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRibbonThetaVault} from "src/interfaces/IRibbonThetaVault.sol";

contract RibbonV2Cellar is Multicall, Ownable {
    /**
     * @notice RibbonThetaVault ETH Call contract. Used to deposit and withdraw from the current position.
     */
    IRibbonThetaVault public immutable ribbonEthCallVault; // 0x25751853Eab4D0eB3652B5eB6ecB102A2789644B

    constructor(IRibbonThetaVault _ribbonEthCallVault) {
        ribbonEthCallVault = _ribbonEthCallVault;
    }

    // Deposit ETH
    function deposit() public payable returns (uint256 shares) {
        ribbonEthCallVault.depositETH{value: msg.value}();
    }
}
