// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionLibrary.sol";
import "../interface/IAutomationRegistrarInterface.sol";
import "../interface/IAutomationRegistryInterface.sol";

library AppLibrary {

    struct Layout {
        address owner;

        address nftContractAddress;

        address auctionTokenFacetAddress;

        uint auctionCount;

        mapping(address => uint256) balances;

        mapping(address => mapping(address => uint256)) allowances;

        mapping (uint => AuctionLibrary.AuctionDetails) auctions;

        AuctionLibrary.AuctionDetails[] auctionsArray;

        mapping (uint256 => mapping (address => bool)) auctionsParticipant;

        mapping (uint256 => address[]) auctionsParticipantArray;

        mapping (address => uint256[]) userAuctionsParticipation;

        mapping (address => uint256[]) userAuctionsCreated;

        address teamWallet;

        mapping(uint => mapping(address => bool)) aunctionWinnerNFTClaim;

        mapping(uint => mapping(address => bool)) aunctionParticipantNFTClaim;

        ChainlinkLibrary.RegistrationParams chainlinkRegParams;

        Authorization authorizationContract;

        AuctionNFT auctionNFTContract;

        LinkTokenInterface i_link;

        IAutomationRegistrarInterface i_registrar;

        IAutomationRegistryInterface i_registry;
    }

    // Convert uint256 to bytes
    function uintToBytes(uint256 _value) internal pure returns (bytes memory) {
        return abi.encodePacked(_value);
    }

    // Convert bytes to uint256
    function bytesToUint(bytes memory _bytes) internal pure returns (uint256) {
        return abi.decode(_bytes, (uint256));
    }

    // Convert string to bytes
    function stringToBytes(string memory str) internal pure returns (bytes memory) {
        return bytes(str);
    }

    // Convert bytes to string
    function bytesToString(bytes memory byteArray) internal pure returns (string memory) {
        return string(byteArray);
    }

}