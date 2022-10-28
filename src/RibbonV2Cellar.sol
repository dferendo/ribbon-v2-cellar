// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {Multicall} from "./base/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract RibbonV2Cellar is Multicall, Ownable {

    constructor() {
            // Initialize immutables.
        }
}