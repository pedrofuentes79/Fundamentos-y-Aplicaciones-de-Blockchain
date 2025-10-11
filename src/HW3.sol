// SPDX-License-Identifier: GPL-3.0

// This makes sure we use a solidity version that automatically handles
// overflow/underflow for me :D. It reverts the operation if it overflows/underflows.
pragma solidity ^0.8.0;

contract Token12 {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Sell(address indexed from, uint256 value);

    constructor() {
        owner = msg.sender;
        _totalSupply = 0;
    }

    function getName() public pure returns (string memory) {
        return "Token12";
    }

    function getSymbol() public pure returns (string memory) {
        return "T12";
    }

    function getPrice() public pure returns (uint128) {
        // Dinamico? o lo fijo yo y listo?
        return 600 wei;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public payable returns (bool) {
        require(balances[msg.sender] >= value);
        require(value > 0);
        require(to != address(0));
        
        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function mint(address to, uint256 value) public returns (bool) {
        require(msg.sender == owner);
        require(to != address(0));
        require(value > 0);

        emit Mint(to, value);

        // update my state
        balances[to] += value;
        _totalSupply += value;


        return true;
    }

    function sell(uint256 value) public returns (bool) {
        require(value > 0);
        // In order to sell, I need to have enough tokens in the contract. This is to avoid users calling sell() when I (owner) have closed the contract. 
        // However, they can still call transfer() to transfer tokens to other addresses, though they won't be able to sell them.
        require(_totalSupply >= value);
        require(balances[msg.sender] >= value);

        // overflow is handled by ^0.8.0
        uint256 toTransfer = value * getPrice();
        // attempt to transfer first. In case of failure here, we don't modify the state.
        transfer(msg.sender, toTransfer);

        emit Sell(msg.sender, value);

        // update my state
        balances[msg.sender] -= value;
        _totalSupply -= value;

        return true;
    }

    function close() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
        _totalSupply = 0;

        // I don't reset balances here, just to keep track of the holders (in the case that I'd fund this contract again? so that the holders can still use their tokens)

    }


    fallback() external payable {
        // fallback function to receive ether
    }
    
    receive() external payable {
        // receive function to receive ether
    }



}