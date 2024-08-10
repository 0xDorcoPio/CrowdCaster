// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdCaster {
    address public owner;
    uint public goal;
    uint public deadline;
    bool public goalReached;
    mapping(address => uint) public contributions;
    address[] public contributors;

    constructor(uint _goal, uint _deadline) {
        owner = msg.sender;
        goal = _goal;
        deadline = _deadline;
        goalReached = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    // Function to contribute to the campaign
    function contribute() public payable {
        require(block.timestamp < deadline, "The campaign is over");
        require(msg.value > 0, "Contribution must be greater than zero");

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;
    }

    // Function to check the total funds raised
    function totalFunds() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < contributors.length; i++) {
            total += contributions[contributors[i]];
        }
        return total;
    }

    // Function to check if the goal has been reached
    function checkGoal() public {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        uint total = totalFunds();
        if (total >= goal) {
            goalReached = true;
        }
    }

    // Function for refunds in case the goal is not reached
    function refund() public {
        // TODO: prevent somebody to scam and retrieve money
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(!goalReached, "Goal has been reached, no refunds");

        uint contributed = contributions[msg.sender];
        require(contributed > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);
    }

    // Function to withdraw funds if the goal is reached
    function withdrawFunds() public onlyOwner {
        require(goalReached, "Goal not reached");
        payable(owner).transfer(address(this).balance);
    }
}