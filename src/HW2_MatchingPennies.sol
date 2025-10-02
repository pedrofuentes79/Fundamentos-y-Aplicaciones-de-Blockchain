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

    // Example:
    //   bytes32 commitment = keccak256(abi.encode(true, "mySecret123"));
    //   commitPlay(commitment) {value: 0.05 ether}
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

    // Example:
    //   revealPlay(my_choice, "mySecret123"), 
    //      where "mySecret123" is the secret used in commitPlay
    function revealPlay(bool value, string memory secret) public {
        require(playerA != address(0) && playerB != address(0), "Both players must have played");

        bytes32 hash = keccak256(abi.encode(value, secret));

        if (msg.sender == playerA) {
            require(!revealedA, "Player A has already revealed");
            require(hash == commitmentA, "Commitment does not match");
            valueA = value;
            revealedA = true;
        } else if (msg.sender == playerB) {
            require(!revealedB, "Player B has already revealed");
            require(hash == commitmentB, "Commitment does not match");
            valueB = value;
            revealedB = true;
        } else {
            revert("Not a player");
        }

        if (revealedA && revealedB) {
            determineWinner();
        }
    }

    function determineWinner() private {
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
        require(balance > 0, "No balance to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    // Idea: agregar una funcion `forfeit` (rendirse)
    // que puede ser llamada por A para retirar sus fondos si
    // no hubo ningun jugador B que se haya unido a la partida.
    // Esta funcion chequearia que el sender sea A, que B no haya jugado
    // y le dejaria a A sus fondos en `balances[playerA]`


}