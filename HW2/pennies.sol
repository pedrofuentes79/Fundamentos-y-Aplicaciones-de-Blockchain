// SPDX-License-Identifier: GPL-3.0

// This makes sure we use a solidity version that automatically handles
// overflow/underflow for me :D. It reverts the operation if it overflows/underflows.
pragma solidity ^0.8.0;

contract MatchingPennies {
    address public playerA;
    address public playerB;
    bool public valueA;
    bool public valueB;
    uint256 public constant REWARD = 0.1 ether;
    mapping(address => uint256) public balances;


    function play(bool value) public payable {
        require(msg.value == REWARD / 2, "Must pay half the reward to play");
        
        // if A hasn't played yet
        if (playerA == address(0)) {
            playerA = msg.sender;
            valueA = value;
            return; 
        } else {
            playerB = msg.sender;
            valueB = value;
        }

        // When reaching this point, we know that both have played
        address winner;
        if (valueA == valueB){
            winner = playerA;
        } else {
            winner = playerB;
        }

        // clean up the state
        playerA = address(0);
        playerB = address(0);
        valueA = false;
        valueB = false;

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