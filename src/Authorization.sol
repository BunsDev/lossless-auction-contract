// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Authorization {
    struct User {
        address walletAddress;
        string email;
    }

    uint256 userCount;
    mapping(address => User) public userDetails;
    mapping(address => bool) public registeredUsers;

    event UserRegistered(address indexed eventUserAddress);
    event ProfileEdited(address indexed eventUserAddress);

    // Modifier to check if user is registered
    modifier onlyRegistered() {
        require(registeredUsers[msg.sender], "User is not registered");
        _;
    }

    // Register user with their wallet address and email
    function registerUser(string memory _email) public {
        require(!registeredUsers[msg.sender], "User is already registered");
        
        User memory newUser = User({
            walletAddress: msg.sender,
            email: _email
        });

        userDetails[msg.sender] = newUser;
        registeredUsers[msg.sender] = true;

        emit UserRegistered(msg.sender);
        userCount++;
    }

    // Get user details
    function getUserDetails(address _userAddress) public view returns (address, string memory) {
        User memory user = userDetails[_userAddress];
        return (user.walletAddress, user.email);
    }

    // Edit user email
    function editEmail(string memory _email) public onlyRegistered {
        User storage user = userDetails[msg.sender];

        user.email = _email;
        
        emit ProfileEdited(msg.sender);
    }

    function isRegisteredUsers(address _userAddress) external view returns(bool){
        return registeredUsers[_userAddress];
    }
}