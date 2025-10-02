// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MatchingPennies.sol";

contract MatchingPenniesTest is Test {
    MatchingPennies public game;
    address playerA = makeAddr("playerA");
    address playerB = makeAddr("playerB");
    address playerC = makeAddr("playerC");
    uint256 constant REWARD = 0.1 ether;
    uint256 constant HALF_REWARD = 0.05 ether;

    function setUp() public {
        game = new MatchingPennies();
        vm.deal(playerA, 10 ether);
        vm.deal(playerB, 10 ether);
        vm.deal(playerC, 10 ether);
    }

    function testCommitPlayAsFirstPlayer() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        assertEq(game.playerA(), playerA);
        assertEq(game.commitmentA(), commitmentA);
    }

    function testCommitPlayAsBothPlayers() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        assertEq(game.playerA(), playerA);
        assertEq(game.playerB(), playerB);
        assertEq(game.commitmentA(), commitmentA);
        assertEq(game.commitmentB(), commitmentB);
    }

    function testRevertIfNotEnoughPayment() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        
        vm.prank(playerA);
        vm.expectRevert("Must pay half the reward to play");
        game.commitPlay{value: 0.01 ether}(commitmentA);
    }

    function testRevertIfPlayerAPlaysAgain() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        bytes32 commitmentA2 = keccak256(abi.encode(false, "secretA2"));
        vm.prank(playerA);
        vm.expectRevert("Player A cannot play again");
        game.commitPlay{value: HALF_REWARD}(commitmentA2);
    }

    function testRevertIfThirdPlayerTriesToJoin() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        bytes32 commitmentC = keccak256(abi.encode(true, "secretC"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerC);
        vm.expectRevert("Game already started");
        game.commitPlay{value: HALF_REWARD}(commitmentC);
    }

    function testRevealPlaySuccessfully() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        assertEq(game.revealedA(), true);
        assertEq(game.valueA(), true);
    }

    function testRevertIfRevealBeforeBothCommitted() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerA);
        vm.expectRevert("Both players must have played");
        game.revealPlay(true, "secretA");
    }

    function testRevertIfWrongCommitment() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        vm.expectRevert("Commitment does not match");
        game.revealPlay(false, "wrongSecret");
    }

    function testRevertIfPlayerRevealsAgain() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerA);
        vm.expectRevert("Player A has already revealed");
        game.revealPlay(true, "secretA");
    }

    function testRevertIfNonPlayerReveals() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerC);
        vm.expectRevert("Not a player");
        game.revealPlay(true, "secretC");
    }

    function testPlayerAWinsWhenValuesMatch() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(true, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerB);
        game.revealPlay(true, "secretB");
        
        // Player A should win
        assertEq(game.balances(playerA), REWARD);
        assertEq(game.balances(playerB), 0);
    }

    function testPlayerBWinsWhenValuesDiffer() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerB);
        game.revealPlay(false, "secretB");
        
        // Player B should win
        assertEq(game.balances(playerA), 0);
        assertEq(game.balances(playerB), REWARD);
    }

    function testGameStateResetAfterWinner() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(false, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerB);
        game.revealPlay(false, "secretB");
        
        // Check game state is reset
        assertEq(game.playerA(), address(0));
        assertEq(game.playerB(), address(0));
        assertEq(game.revealedA(), false);
        assertEq(game.revealedB(), false);
        assertEq(game.valueA(), false);
        assertEq(game.valueB(), false);
        assertEq(game.commitmentA(), bytes32(0));
        assertEq(game.commitmentB(), bytes32(0));
    }

    function testGetBalanceReturnsCorrectAmount() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(true, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerB);
        game.revealPlay(true, "secretB");
        
        vm.prank(playerA);
        uint256 balance = game.getBalance();
        assertEq(balance, REWARD);
    }

    function testWithdrawSuccessfully() public {
        bytes32 commitmentA = keccak256(abi.encode(true, "secretA"));
        bytes32 commitmentB = keccak256(abi.encode(true, "secretB"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA");
        
        vm.prank(playerB);
        game.revealPlay(true, "secretB");
        
        uint256 initialBalance = playerA.balance;
        
        vm.prank(playerA);
        game.withdraw();
        
        assertEq(playerA.balance, initialBalance + REWARD);
        assertEq(game.balances(playerA), 0);
    }

    function testRevertIfWithdrawWithNoBalance() public {
        vm.prank(playerA);
        vm.expectRevert("No balance to withdraw");
        game.withdraw();
    }

    function testPlayMultipleRounds() public {
        // First round
        bytes32 commitmentA1 = keccak256(abi.encode(true, "secretA1"));
        bytes32 commitmentB1 = keccak256(abi.encode(true, "secretB1"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA1);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB1);
        
        vm.prank(playerA);
        game.revealPlay(true, "secretA1");
        
        vm.prank(playerB);
        game.revealPlay(true, "secretB1");
        
        assertEq(game.balances(playerA), REWARD);
        
        // Second round
        bytes32 commitmentA2 = keccak256(abi.encode(false, "secretA2"));
        bytes32 commitmentB2 = keccak256(abi.encode(true, "secretB2"));
        
        vm.prank(playerA);
        game.commitPlay{value: HALF_REWARD}(commitmentA2);
        
        vm.prank(playerB);
        game.commitPlay{value: HALF_REWARD}(commitmentB2);
        
        vm.prank(playerA);
        game.revealPlay(false, "secretA2");
        
        vm.prank(playerB);
        game.revealPlay(true, "secretB2");
        
        // Player B wins second round, Player A still has first round winnings
        assertEq(game.balances(playerA), REWARD);
        assertEq(game.balances(playerB), REWARD);
    }
}

