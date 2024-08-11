// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowd2 {
    address public owner;
    uint public goal;
    uint public deadline;
    bool public goalReached;
    mapping(address => uint) public contributions;
    address[] public contributors;
    bool internal locked;

    uint public requestedAmount;
    uint public voteDeadline;
    bool public voteActive;

    mapping(address => bool) public hasVoted;
    uint public yesVotes;
    uint public noVotes;
    uint public totalVotingPower;

    event ContributionReceived(address contributor, uint amount);
    event GoalReached(uint totalAmount);
    event FundsWithdrawn(address owner, uint amount);
    event RefundIssued(address contributor, uint amount);
    event WithdrawalRequested(uint amount);
    event VoteCast(address voter, bool vote);
    event VoteResult(bool approved);

    constructor(uint _goal, uint _duration) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
        goalReached = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // Function to contribute to the campaign
    function contribute() public payable {
        require(block.timestamp < deadline, "The campaign is over");
        require(msg.value > 0, "Contribution must be greater than zero");

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;

        emit ContributionReceived(msg.sender, msg.value);
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
        require(!goalReached, "Goal already reached");

        uint total = totalFunds();
        if (total >= goal) {
            goalReached = true;
            emit GoalReached(total);
        }
    }

    // Function for refunds in case the goal is not reached
    function refund() public noReentrancy {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(!goalReached, "Goal has been reached, no refunds");

        uint contributed = contributions[msg.sender];
        require(contributed > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit RefundIssued(msg.sender, contributed);
    }

    // Function to request fund withdrawal
    function requestWithdrawal(uint _amount) public onlyOwner {
        require(goalReached, "Goal not reached");
        require(_amount <= address(this).balance, "Requested amount exceeds balance");
        require(!voteActive, "Another vote is active");

        requestedAmount = _amount;
        voteDeadline = block.timestamp + 1 minutes; // Set voting period (e.g., 1 day)
        voteActive = true;
        yesVotes = 0;
        noVotes = 0;
        totalVotingPower = totalFunds();

        for (uint i = 0; i < contributors.length; i++) {
            hasVoted[contributors[i]] = false;
        }

        emit WithdrawalRequested(_amount);
    }

    // Function to cast a vote
    function vote(bool approve) public {
        require(voteActive, "No active vote");
        require(block.timestamp <= voteDeadline, "Voting period has ended");
        require(contributions[msg.sender] > 0, "Only contributors can vote");
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        uint votingPower = contributions[msg.sender];

        if (approve) {
            yesVotes += votingPower;
        } else {
            noVotes += votingPower;
        }

        emit VoteCast(msg.sender, approve);
    }

    // Function to finalize the vote
    function finalizeVote() public {
        require(voteActive, "No active vote");
        require(block.timestamp > voteDeadline, "Voting period has not ended");

        voteActive = false;
        uint totalVotes = yesVotes + noVotes;

        // If not enough voting power has voted, assume approval
        bool approved = (yesVotes > noVotes) || (totalVotes < (totalVotingPower / 2));

        if (approved && requestedAmount <= address(this).balance) {
            payable(owner).transfer(requestedAmount);
            emit FundsWithdrawn(owner, requestedAmount);
        }

        emit VoteResult(approved);
    }

    receive() external payable {
        contribute();
    }
}
