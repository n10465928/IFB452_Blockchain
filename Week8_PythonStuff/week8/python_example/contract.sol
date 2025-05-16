// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventChain {
    mapping(address => bool) public status;

    event Added(address indexed user);
    event Approved(address indexed user);

    function addUser() public {
        status[msg.sender] = false;
        emit Added(msg.sender);
    }

    function approveUser(address user) public {
        status[user] = true;
        emit Approved(user);
    }

    function getStatus(address user) public view returns (bool) {
        return status[user];
    }
}
