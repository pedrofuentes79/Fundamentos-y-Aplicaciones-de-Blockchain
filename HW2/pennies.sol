// SPDX-License-Identifier: GPL-3.0

// This makes sure we use a solidity version that automatically handles
// overflow/underflow for me :D. It reverts the operation if it overflows/underflows.
pragma solidity ^0.8.0;

contract MatchingPennies {
    address public playerA;
    address public playerB;
    bool public valueA;
    bool public revealedA;
    bool public valueB;
    bool public revealedB;
    bytes32 public commitmentA;
    bytes32 public commitmentB;
    uint256 public constant REWARD = 0.1 ether;
    mapping(address => uint256) public balances;


    function commitPlay(bytes32 commitment) public payable {
        require(msg.value == REWARD / 2, "Must pay half the reward to play");
        
        // if A hasn't played yet
        if (playerA == address(0)) {
            playerA = msg.sender;
            commitmentA = commitment;
            return;
        } else if (playerB == address(0)) {
            require(msg.sender != playerA, "Player A cannot play again");
            playerB = msg.sender;
            commitmentB = commitment;
            return;
        } else {
            revert("Game already started");
        }
    }

    function revealPlay(bool value, string memory secret) public {
        require(playerA != address(0) && playerB != address(0), "Both players must have played");

        bytes32 hash = keccak256(abi.encodePacked(value, secret));

        if (msg.sender == playerA) {
            require(!revealedA, "Player A has already revealed");
            require(hash == commitmentA, "Commitment does not match");
            valueA = value;
        } else if (msg.sender == playerB) {
            require(!revealedB, "Player B has already revealed");
            require(hash == commitmentB, "Commitment does not match");
            valueB = value;
        } else {
            revert("Not a player");
        }

        if (revealedA && revealedB) {
            determineWinner();
        }
    }

    function determineWinner() public {
        require(revealedA && revealedB, "Both players must have revealed");

        address winner;
        if (valueA == valueB){
            winner = playerA;
        } else {
            winner = playerB;
        }

        // clean up the state
        playerA = address(0);
        playerB = address(0);
        revealedA = false;
        revealedB = false;
        valueA = false;
        valueB = false;
        commitmentA = bytes32(0);
        commitmentB = bytes32(0);

        // have the winner be able to retrieve the funds later.
        balances[winner] += REWARD;
    } 

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }


}