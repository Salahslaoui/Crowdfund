// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {

    mapping(address => bool) public minters;

    constructor() ERC20("CrowdReward", "CRWD") Ownable(msg.sender) {}

    function setMinter(address minter, bool allowed) external onlyOwner {
        minters[minter] = allowed;
    }

    function mint(address to, uint amount) external {
        require(minters[msg.sender], "Not authorized to mint");
        _mint(to, amount);
    }
}