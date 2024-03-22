// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';

contract ZTestToken is ERC20, Pausable, Ownable {
  constructor(address initialOwner) ERC20('ZTest Token', 'ZTT') Ownable(initialOwner) {
    _mint(msg.sender, 1_000_000 * 10 ** decimals());
    _pause();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _update(address from, address to, uint256 value) internal override(ERC20) {
    require(to != address(this), 'ZToken: cannot transfer tokens to token contract');
    // Token transfers are only possible if the contract is not paused
    // OR if triggered by the owner of the contract
    require(!paused() || owner() == _msgSender(), 'ZToken: token transfer while paused');
    super._update(from, to, value);
  }
}