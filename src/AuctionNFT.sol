// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract AuctionNFT is ERC721URIStorage {
    address owner;
    string winnerImageURI;
    string participantImageURI;
    address mintingAddress;

    using Strings for uint256;
    uint256 private tokenIds;

    mapping(uint256 => uint256) public tokenIdToLevels;

    error ONLY_OWNER();
    error NOT_MINTING_ADDRESS();

    constructor(address _mintingAddress) ERC721("losslessNFT", "LAU") {
        owner = msg.sender;
        mintingAddress = _mintingAddress;
    }

    function winnerTokenURI(uint256 _aunctionId) public view returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        string memory name = string(abi.encodePacked("Auction #", Strings.toString(_aunctionId), " Winner NFT"));
        string memory json = string(
            abi.encodePacked(
                '{"name": "', name, '",',
                '"auctionID": "', Strings.toString(_aunctionId), '",',
                '"description": "A proof of Aunction Winning NFT",',
                '"image": "', winnerImageURI, '"}'
            )
        );
        string memory jsonBase64Encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURL, jsonBase64Encoded));
    }

    function particantTokenURI(uint256 _aunctionId) public view returns (string memory){
        string memory baseURL = "data:application/json;base64,";
        string memory name = string(abi.encodePacked("Auction #", Strings.toString(_aunctionId), " Participant NFT"));
        string memory json = string(
            abi.encodePacked(
                '{"name": "', name, '",',
                '"auctionID": "', Strings.toString(_aunctionId), '",',
                '"description": "A proof of Aunction Participation NFT",',
                '"image": "', participantImageURI, '"}'
            )
        );
        string memory jsonBase64Encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURL, jsonBase64Encoded));
    }

    function mintWinnerNFT(uint256 _aunctionId, address minto) public {
        if(msg.sender != mintingAddress) revert NOT_MINTING_ADDRESS();
        
        string memory tokenURI = winnerTokenURI(_aunctionId);

        uint256 newItemId = tokenIds + 1;

        _safeMint(minto, newItemId);
        _setTokenURI(newItemId, tokenURI);

        tokenIds++;
    }

    function mintParticipantNFT(uint256 _aunctionId, address minto) public {
        if(msg.sender != mintingAddress) revert NOT_MINTING_ADDRESS();

        string memory tokenURI = particantTokenURI(_aunctionId);

        uint256 newItemId = tokenIds + 1;

        _safeMint(minto, newItemId);
        _setTokenURI(newItemId, tokenURI);

        tokenIds++;
    }

    function updateWinnerImageURI(string memory _winnerImageURI) external {
        if(msg.sender != owner)revert ONLY_OWNER();
        
        winnerImageURI = _winnerImageURI;
    }

    function updateParticpantImageURI(string memory _particpantImageURI) external {
        if(msg.sender != owner)revert ONLY_OWNER();
        
        participantImageURI = _particpantImageURI;
    }

    function updateMintingAddress(address _mintingAddress) external {
        if(msg.sender != owner)revert ONLY_OWNER();

        mintingAddress = _mintingAddress;
    }
}