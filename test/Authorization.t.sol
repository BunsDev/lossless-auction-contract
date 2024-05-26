// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Authorization} from "../src/Authorization.sol";

contract AuthorizationTest is Test {
    Authorization public authorization;

    function setUp() public {
        authorization = new Authorization();
    }

    function testRegistration() public {
    }
}