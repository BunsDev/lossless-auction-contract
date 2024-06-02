// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppLibrary.sol";
import "./AuctionLibrary.sol";

library ChainlinkLibrary {
    using AppLibrary for bytes;
    using AppLibrary for uint256;

    struct RegistrationParams {
        
        string name;

        bytes encryptedEmail;

        address upkeepContract;

        uint32 gasLimit;

        address adminAddress;

        uint8 triggerType;

        bytes checkData;

        bytes triggerConfig;

        bytes offchainConfig;

        uint96 amount;
    }

    error ONLY_OWNER();

    function createAutomationKeeper(uint256 _auctionId, string memory _name, AppLibrary.Layout storage layout) external returns (uint256) {

        RegistrationParams memory _regParam = layout.chainlinkRegParams;

        _regParam.name =  _name;
        
        _regParam.checkData = AppLibrary.uintToBytes(_auctionId);

        layout.i_link.approve(address(layout.i_registrar), _regParam.amount);
        
        uint256 upkeepID =layout.i_registrar.registerUpkeep(_regParam);
        
        if (upkeepID != 0) {
            return upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function approveRegistrar(uint256 _amount, AppLibrary.Layout storage layout) external {
        if(msg.sender != layout.owner)revert ONLY_OWNER();
        
        layout.i_link.approve(address(layout.i_registrar), _amount);
    }

    function updateAutomationRegParams(string memory _email, uint32 _gasLimit, address _adminAddress, uint96 _amount, AppLibrary.Layout storage layout) external {
        if(msg.sender != layout.owner)revert ONLY_OWNER();
        
        RegistrationParams storage params = layout.chainlinkRegParams;
        
        params.encryptedEmail = bytes(_email);
        
        params.gasLimit = _gasLimit;
        
        params.adminAddress = _adminAddress;
        
        params.amount = _amount;
    }

    function checkUpkeep( bytes calldata checkData, AppLibrary.Layout storage layout) external view returns (bool upkeepNeeded, bytes memory performData){
        
        AuctionLibrary.AuctionDetails storage ad = layout.auctions[checkData.bytesToUint()];
        
        upkeepNeeded = block.timestamp > ad.endingTime && !ad.ended;
        
        performData = checkData; 
    }

    function cancelUpkeep(uint256 _upkeepID, AppLibrary.Layout storage layout) external { 
        layout.i_registry.cancelUpkeep(_upkeepID);
    }
}