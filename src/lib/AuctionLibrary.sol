// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LinkTokenInterface} from "../../lib/chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "../Authorization.sol";
import "../AuctionNFT.sol";
import "./AppLibrary.sol";
import "./ChainlinkLibrary.sol";


library AuctionLibrary {

    struct AuctionDetails {

        address auctionCreator;

        address nftContractAddress;

        address hightestBidder;

        address previousBidder;

        uint256 startingTime;

        uint256 endingTime;

        uint256 nftTokenId;

        uint256 auctionId;

        uint256 auctionCreatedTime;

        uint256 currentBid;

        uint256 previousBid;

        uint256 minValidBid;

        address lastInteractor;

        uint256 keeperId;

        string imageURI;

        bool ended;
    }

    error ONLY_OWNER();
    error ONLY_NFT_OWNER();
    error ONLY_TOKEN_OWNER();
    error ZERO_PRICE_NOT_PERMITTED();
    error AUCTION_ID_NOT_FOUND();
    error BID_LESS_THAN_EXISTING_BID();
    error AUCTION_ENDED();
    error AUCTION_NOT_ENDED();
    error AUCTION_NOT_STARTED();
    error NOT_A_VALID_BID();
    error NOT_AUCTION_CREATOR();
    error INSUFFICIENT_BALANCE();
    error AUCTION_IN_PROGRESS();
    error NOT_HIGHEST_BIDDER();
    error NOT_WINNER();
    error NOT_PARTICIPANT();
    error CREATOR_CANNOT_BID();
    error NOT_FOR_WINNER();
    error ZERO_DURATION_NOT_PERMITTED();
    error WINNER_NFT_ALREADY_CLAIMED();
    error PARTICIPANT_NFT_ALREADY_CLAIMED();

    event HighestBidder(address indexed eventBidderAddress);

    function createAuction(uint _startingTime, uint _endingTime, uint _startingBid, uint _nftTokenId, address _nftContractAddress, string memory _imageURI, AppLibrary.Layout storage layout) external  {

        // checking user inputs
        if (_endingTime - _startingTime == 0) revert ZERO_DURATION_NOT_PERMITTED();

        if (_startingBid == 0) revert ZERO_PRICE_NOT_PERMITTED();

        // checking for owner of the NFT
        if (IERC721(_nftContractAddress).ownerOf(_nftTokenId) != msg.sender) revert ONLY_NFT_OWNER();

        // transferring NFT to Contract
        IERC721(_nftContractAddress).transferFrom(msg.sender, address(this), _nftTokenId);

        uint _newAuctionCount = layout.auctionCount;

        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_newAuctionCount];

        // setting auction details
        ad.auctionCreator = msg.sender;

        ad.nftContractAddress = _nftContractAddress;

        ad.auctionId = _newAuctionCount;

        ad.startingTime = _startingTime;

        ad.endingTime = _endingTime;

        ad.nftTokenId = _nftTokenId;

        ad.currentBid = _startingBid;

        ad.minValidBid = 120 * ad.currentBid / 100;

        ad.auctionCreatedTime = block.timestamp;

        ad.imageURI = _imageURI;
        
        uint _keeperId = ChainlinkLibrary.createAutomationKeeper(ad.auctionId, Strings.toString(ad.auctionId), layout);

        ad.keeperId = _keeperId;

        layout.auctionsArray.push(ad);

        layout.userAuctionsCreated[msg.sender].push(ad.auctionId);

        // incrementing auctionCount
        layout.auctionCount++;
    }

    function bid(uint _auctionId, AppLibrary.Layout storage layout) external returns (address highestBidder_) {

        uint256 _bidderBalance = address(msg.sender).balance;

        if(_bidderBalance < msg.value) revert INSUFFICIENT_BALANCE();

        if(layout.auctions[_auctionId].auctionCreator == msg.sender) revert CREATOR_CANNOT_BID();

        if(layout.auctions[_auctionId].auctionCreator == address(0)) revert AUCTION_ID_NOT_FOUND();

        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_auctionId];

        if(block.timestamp < ad.startingTime) revert AUCTION_NOT_STARTED();

        if(block.timestamp > ad.endingTime || ad.ended) revert AUCTION_ENDED();

        if(msg.value < ad.currentBid) revert BID_LESS_THAN_EXISTING_BID();

        if(msg.value < ad.minValidBid) revert NOT_A_VALID_BID();

        ad.previousBid = ad.currentBid;

        ad.currentBid = msg.value; 

        if (ad.hightestBidder == address(0)){

            ad.hightestBidder = msg.sender;

            highestBidder_ = msg.sender;

            layout.auctionsArray[_auctionId]= ad;

            layout.userAuctionsParticipation[msg.sender].push(_auctionId);

            addToAuctionParticipant(_auctionId, msg.sender, layout);

            return highestBidder_;

        } else {

            ad.previousBidder = ad.hightestBidder;

            ad.hightestBidder = msg.sender;

            highestBidder_ = msg.sender;

            ad.lastInteractor = msg.sender;

            totalFeeDistribution(msg.value, _auctionId, layout);

            layout.auctionsArray[_auctionId]= ad;
        
            layout.userAuctionsParticipation[msg.sender].push(_auctionId);

            addToAuctionParticipant(_auctionId, msg.sender, layout);

            return highestBidder_;
        }
    }

    function getAllAuction(AppLibrary.Layout storage layout) external view returns (AuctionDetails[] memory){
        return layout.auctionsArray;
    }

    function getUserAuctionCreated(address userAddress, AppLibrary.Layout storage layout) external view returns (AuctionDetails[] memory){
        uint256[] storage userAuntionIds = layout.userAuctionsCreated[userAddress];
        AuctionLibrary.AuctionDetails[] memory userAunctionList = new AuctionLibrary.AuctionDetails[](userAuntionIds.length);

        for (uint256 i = 0; i < layout.userAuctionsCreated[userAddress].length; i++) {
            userAunctionList[i] = layout.auctionsArray[userAuntionIds[i]];
        }

        return userAunctionList;
    }

    function addToAuctionParticipant(uint256 _auctionId, address _user, AppLibrary.Layout storage layout) private {
        if (!layout.auctionsParticipant[_auctionId][_user]){
            layout.auctionsParticipant[_auctionId][_user] = true;
            layout.auctionsParticipantArray[_auctionId].push(_user);
        }
    }

    function totalFeeDistribution(uint _bid, uint _auctionId, AppLibrary.Layout storage layout) private {

        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_auctionId];

        uint256 totalFee = (_bid * 10) / 100;

        uint256 teamWalletFee = (totalFee * 40) / 100;

        uint256 previousBidderFee = (totalFee * 50) / 100;

        uint256 lastInteractorFee = (totalFee * 10) / 100;

        payable(layout.teamWallet).transfer(teamWalletFee);

        payable(ad.previousBidder).transfer(previousBidderFee + ad.previousBid);

        payable(ad.hightestBidder).transfer(lastInteractorFee);
        
    }

    function getUserAuctionParticipated(address userAddress, AppLibrary.Layout storage layout) external view returns (AuctionDetails[] memory){
        uint256[] memory userAuntionIds = layout.userAuctionsParticipation[userAddress];
        AuctionLibrary.AuctionDetails[] memory userAunctionList = new AuctionLibrary.AuctionDetails[](userAuntionIds.length);

        for (uint256 i = 0; i < layout.userAuctionsParticipation[userAddress].length; i++) {
            userAunctionList[i] = layout.auctionsArray[userAuntionIds[i]];
        }

        return userAunctionList;
    }

    function getAunctionBidder(uint256 _auctionId, AppLibrary.Layout storage layout) external view returns (address[] memory){
        return layout.auctionsParticipantArray[_auctionId];
    }

    function getAuctionById(uint256 _aunctionId, AppLibrary.Layout storage layout) external view returns (AuctionLibrary.AuctionDetails memory){
        return layout.auctions[_aunctionId];
    }

    function finalizeAuction(uint256 _auctionId, AppLibrary.Layout storage layout) public {

        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_auctionId];

        if(block.timestamp > ad.endingTime && !ad.ended){
            ad.ended = true;

            layout.auctionsArray[_auctionId].ended = true;

            if(ad.hightestBidder == address(0)){
                IERC721(ad.nftContractAddress).transferFrom(address(this), ad.auctionCreator, ad.nftTokenId);
            }
            else{
                IERC721(ad.nftContractAddress).transferFrom(address(this), ad.hightestBidder, ad.nftTokenId);

                uint _nftValue = ad.currentBid * 90 /100;

                payable(ad.auctionCreator).transfer(_nftValue);

                emit HighestBidder(ad.hightestBidder);
            }
        }
    }

    function claimAuctionWinnerNFT(uint256 _auctionId, AppLibrary.Layout storage layout) external {
        
        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_auctionId];

        if(ad.auctionCreator == msg.sender) revert CREATOR_CANNOT_BID();

        if(ad.auctionCreator == address(0)) revert AUCTION_ID_NOT_FOUND();

        if(block.timestamp < ad.startingTime) revert AUCTION_NOT_STARTED();

        if(block.timestamp < ad.endingTime || !ad.ended) revert AUCTION_NOT_ENDED();

        if(ad.hightestBidder != msg.sender) revert NOT_HIGHEST_BIDDER();

        if(layout.aunctionWinnerNFTClaim[_auctionId][msg.sender]) revert WINNER_NFT_ALREADY_CLAIMED();

        layout.auctionNFTContract.mintWinnerNFT(_auctionId, msg.sender);
    }

    function claimAuctionParticipantNFT(uint256 _auctionId, AppLibrary.Layout storage layout) external {
        
        AuctionLibrary.AuctionDetails storage ad = layout.auctions[_auctionId];

        if(ad.auctionCreator == msg.sender) revert CREATOR_CANNOT_BID();

        if(ad.auctionCreator == address(0)) revert AUCTION_ID_NOT_FOUND();

        if(block.timestamp < ad.startingTime) revert AUCTION_NOT_STARTED();

        if(block.timestamp < ad.endingTime || !ad.ended) revert AUCTION_NOT_ENDED();

        if(ad.hightestBidder == msg.sender) revert NOT_FOR_WINNER();

        if(layout.aunctionParticipantNFTClaim[_auctionId][msg.sender]) revert PARTICIPANT_NFT_ALREADY_CLAIMED();

        layout.auctionNFTContract.mintParticipantNFT(_auctionId, msg.sender);
    }

    function cancelAuction(uint256 _auctionId, AppLibrary.Layout storage layout) external {
        if(layout.auctions[_auctionId].auctionCreator != msg.sender) revert NOT_AUCTION_CREATOR();

        if(layout.auctions[_auctionId].auctionCreator == address(0)) revert AUCTION_ID_NOT_FOUND();

        if(block.timestamp > layout.auctions[_auctionId].startingTime) revert AUCTION_IN_PROGRESS();

        layout.auctions[_auctionId].ended = true;

        layout.auctionsArray[_auctionId].ended = true;
    }

    function changeTeamWallet(address _teamWallet, AppLibrary.Layout storage layout) external {
        if(msg.sender != layout.owner)revert ONLY_OWNER();
        
        layout.teamWallet = _teamWallet;
    }

    function changeAunctionProofNFT(address _aunctionNFTAddress, AppLibrary.Layout storage layout) external {
        if(msg.sender != layout.owner)revert ONLY_OWNER();

        layout.auctionNFTContract = AuctionNFT(_aunctionNFTAddress);
    }
 
}