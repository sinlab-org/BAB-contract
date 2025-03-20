// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBABFactory.sol";
import "./BAB.sol";
import "hardhat/console.sol";

contract BABFactory is IBABFactory, Ownable {

  error InsufficientFee();

  event BABTokenCreated(address indexed tokenAddress, address indexed creator, string name, string symbol, string tokenURI, address validator, Config config);

  Config private config;

  constructor(Config memory _config) Ownable(msg.sender) {
    config = _config;
  }

  function createToken(string memory name, string memory symbol, address validator, string memory tokenUri, bytes32 _salt) external payable returns (address) {
    if (msg.sender != owner() && msg.value < config.createTokenFee) {
      revert InsufficientFee();
    }
    BAB token = new BAB{salt: _salt, value: msg.value - config.createTokenFee}(name, symbol, tokenUri, address(this), msg.sender, validator);
    emit BABTokenCreated(address(token), msg.sender, name, symbol, tokenUri, validator, config);
    return address(token);
  }

  function setConfig(Config memory _config) external onlyOwner {
    config = _config;
  }

  function getConfig() public view returns (Config memory) {
    return config;
  }

  function transferOwner(address to) external onlyOwner {
    this.transferOwnership(to);
  }

  function withdraw(address to) external onlyOwner {
    (bool success, ) = to.call{value: address(this).balance}("");
    require(success, "Failed to withdraw");
  }
}
