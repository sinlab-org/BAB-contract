// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './interfaces/IBABValidator.sol';

contract TestValidator is IBABValidator {

  mapping(address => bool) public permission;

  function setPermission(bool isValidate) external {
    permission[msg.sender] = isValidate;
  }

  function validate(address sender, uint256 value, bytes32 data) public view returns (bool) {
    return permission[sender];
  }

}