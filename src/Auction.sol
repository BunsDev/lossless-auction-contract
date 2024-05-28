// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "../lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./lib/AppLibrary.sol";
import "./lib/AuctionLibrary.sol";
import "./lib/ChainlinkLibrary.sol";
import "./interface/IAutomationRegistrarInterface.sol";
import "./interface/IAutomationRegistryInterface.sol";

contract Auction is AutomationCompatibleInterface {
    using AppLibrary for uint256;
    using AppLibrary for bytes;

    AppLibrary.Layout internal layout;


    constructor(address _authorization, address _aunctionNFT, address _teamWallet, LinkTokenInterface link, IAutomationRegistrarInterface registrar, IAutomationRegistryInterface registry, string memory _adminEmail, uint32 _gasLimit, uint96 _amount, address _adminAddress) {
        layout.authorizationContract = Authorization(_authorization);

        layout.auctionNFTContract = AuctionNFT(_aunctionNFT);

        layout.teamWallet = _teamWallet;

        layout.owner = msg.sender;

        layout.chainlinkRegParams.encryptedEmail = bytes(_adminEmail);

        layout.chainlinkRegParams.upkeepContract = address(this);

        layout.chainlinkRegParams.gasLimit = _gasLimit;

        layout.chainlinkRegParams.adminAddress = _adminAddress;

        layout.chainlinkRegParams.triggerType = 0;
        
        layout.chainlinkRegParams.triggerConfig = AppLibrary.uintToBytes(0);
        
        layout.chainlinkRegParams.offchainConfig = AppLibrary.uintToBytes(0);

        layout.chainlinkRegParams.amount = _amount;

        layout.i_link = link;

        layout.i_registrar = registrar;

        layout.i_registry = registry;
    }


    modifier onlyRegistered() {
        require(layout.authorizationContract.isRegisteredUsers(msg.sender), "User is not registered");
        _;
    }

    function createAuction(uint _startingTime, uint _endingTime, uint _startingBid, uint _nftTokenId, address _nftContractAddress, string memory _imageURI) external onlyRegistered {
        AuctionLibrary.createAuction(_startingTime, _endingTime, _startingBid, _nftTokenId, _nftContractAddress, _imageURI, layout);
    }

    function bid(uint _auctionId) external onlyRegistered payable returns (address highestBidder_) {
         highestBidder_ = AuctionLibrary.bid(_auctionId, layout);
    }

    function getAllAuction() external onlyRegistered view returns (AuctionLibrary.AuctionDetails[] memory){
        return AuctionLibrary.getAllAuction(layout);
    }

    function getUserAuctionCreated(address _userAddress) external onlyRegistered view returns (AuctionLibrary.AuctionDetails[] memory){
        return AuctionLibrary.getUserAuctionCreated(_userAddress, layout);
    }

    function getUserAuctionParticipated(address _userAddress) external onlyRegistered view returns (AuctionLibrary.AuctionDetails[] memory){
        return AuctionLibrary.getUserAuctionParticipated(_userAddress, layout);
    }

    function getAunctionBidder(uint256 _auctionId) external onlyRegistered view returns (address[] memory){
        return AuctionLibrary.getAunctionBidder(_auctionId, layout);
    }

    function getAuctionById(uint256 _aunctionId) external onlyRegistered view returns (AuctionLibrary.AuctionDetails memory){
        return AuctionLibrary.getAuctionById(_aunctionId, layout);
    }

    function updateAutomationRegParams(string memory _email, uint32 _gasLimit, address _adminAddress, uint96 _amount) external {
        ChainlinkLibrary.updateAutomationRegParams(_email, _gasLimit, _adminAddress, _amount, layout);
    }

    function approveRegistrar(uint256 _amount) external {
        ChainlinkLibrary.approveRegistrar(_amount, layout);
    }

    function performUpkeep(bytes calldata performData) external override {
        AuctionLibrary.finalizeAuction(performData.bytesToUint(), layout);
    }

    function endAuctionManual(uint256 _auctionId) external {
        AuctionLibrary.finalizeAuction(_auctionId, layout);
    }

    function checkUpkeep( bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData){
       (upkeepNeeded, performData)= ChainlinkLibrary.checkUpkeep(checkData, layout);
    }

    function claimAuctionWinnerNFT(uint256 _auctionId) external onlyRegistered {
        AuctionLibrary.claimAuctionWinnerNFT(_auctionId, layout);
    }

    function claimAuctionParticipantNFT(uint256 _auctionId) external onlyRegistered {
        AuctionLibrary.claimAuctionParticipantNFT(_auctionId, layout);
    }

    function cancelAuction(uint256 _auctionId) external onlyRegistered {
        AuctionLibrary.cancelAuction(_auctionId, layout);
    }

    function changeTeamWallet(address _teamWallet) external {
        AuctionLibrary.changeTeamWallet(_teamWallet, layout);
    }

    function changeAunctionProofNFT(address _aunctionNFTAddress) external {
        AuctionLibrary.changeAunctionProofNFT(_aunctionNFTAddress, layout);
    }
}