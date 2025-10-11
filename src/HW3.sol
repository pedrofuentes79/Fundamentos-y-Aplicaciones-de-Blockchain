// SPDX-License-Identifier: GPL-3.0

// This makes sure we use a solidity version that automatically handles
// overflow/underflow for me :D. It reverts the operation if it overflows/underflows.
pragma solidity ^0.8.0;

contract Token12 {
    address public owner;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public etherBalance;
    uint256 public _totalSupply;
    uint128 public price;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Sell(address indexed from, uint256 value);

    // podria agregar eventos Withdraw, Buy, PriceChanged

    constructor() {
        owner = msg.sender;
        _totalSupply = 0;
        price = 600 wei;
    }

    function getName() public pure returns (string memory) {
        return "Token12";
    }

    function getSymbol() public pure returns (string memory) {
        return "T12";
    }

    function getPrice() public view returns (uint128) {
        return price;
    }

    function changePrice(uint128 newPrice) public {
        require(msg.sender == owner);
        require(newPrice > 0);
        price = newPrice;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenBalance[account];
    }

    function etherBalanceOf(address account) public view returns (uint256) {
        return etherBalance[account];
    }

    // This is to avoid code duplication on `transfer` and `buy`
    function _transfer(address from, address to, uint256 value) internal {
        require(tokenBalance[from] >= value);
        require(value > 0);
        require(to != address(0));
        require(to != from);
        
        tokenBalance[from] -= value;
        tokenBalance[to] += value;

        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function mint(address to, uint256 value) public returns (bool) {
        require(msg.sender == owner);
        require(to != address(0));
        require(value > 0);

        emit Mint(to, value);

        // update my state
        tokenBalance[to] += value;
        _totalSupply += value;


        return true;
    }

    function buy(uint256 value) public returns (bool) {
        // This is not creating new tokens, it's just transferring tokens from the contract itself to the sender
        // However, the contract must have enough tokens to transfer to the sender, which means the contract owner
        // must have minted enough tokens for the contract beforehand.

        require(value > 0);
        // sender must have paid enouth ether to buy the tokens
        uint256 totalEther = value * price;
        require(totalEther <= etherBalance[msg.sender]);
        // the contract itself must have enough tokens to sell to the sender
        require(tokenBalance[address(this)] >= value);

        etherBalance[msg.sender] -= totalEther;
        
        // this buys from the contract itself, so we use _transfer()
        _transfer(address(this), msg.sender, value);

        return true;

    }

    function sell(uint256 value) public returns (bool) {
        require(value > 0);

        // In order to sell, I need to have enough tokens in the contract.
        uint256 totalEther = value * price;
        require(address(this).balance >= totalEther, "Ether currently unavailable in the contract. Contact the owner to fund the contract.");

        // This is to avoid users calling sell() when I (owner) have closed the contract.
        // However, they can still call transfer() to transfer tokens to other addresses, 
        // though they won't be able to sell them.
        require(_totalSupply >= value, "Not enough tokens in the contract. Contact the owner to mint more tokens."); 
        require(tokenBalance[msg.sender] >= value);

        // overflow is handled by ^0.8.0
        etherBalance[msg.sender] += totalEther;

        emit Sell(msg.sender, value);

        // update my state
        tokenBalance[msg.sender] -= value;
        _totalSupply -= value;

        return true;
    }

    function withdraw(uint256 value) public returns (bool) {
        require(value > 0);
        require(etherBalance[msg.sender] >= value);

        // update state after external call
        etherBalance[msg.sender] -= value;

        payable(msg.sender).transfer(value);
        
        return true;
    }



    function close() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
        _totalSupply = 0;

        // I don't reset tokenBalance here, just to keep track of the holders (in the case that I'd fund this contract again? so that the holders can still use their tokens)

    }


    fallback() external payable {
        // save the amount of ether received by the sender
        etherBalance[msg.sender] += msg.value;
    }
    
    receive() external payable {
        // save the amount of ether received by the sender
        etherBalance[msg.sender] += msg.value;
    }



}