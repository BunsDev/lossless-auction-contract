// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/ChainlinkLibrary.sol";

interface IAutomationRegistrarInterface {
    function registerUpkeep(ChainlinkLibrary.RegistrationParams calldata requestParams) external returns (uint256);
}
