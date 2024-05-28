// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutomationRegistryInterface {
    function cancelUpkeep(uint256 id) external;
}