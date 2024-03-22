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

  /**
   * @dev Tokens cannot be transferred to the token contract itself.
   */
  error TransferToTokenContract();

  /**
   * @dev Token transfers can only be initialized by contract owner when paused.
   */
  error TransfersUnathorizedWhenPaused();

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _update(address from, address to, uint256 value) internal override(ERC20) {
    if (to == address(this)) {
      revert TransferToTokenContract();
    }
    if (paused() && owner() != _msgSender()) {
      revert TransfersUnathorizedWhenPaused();
    }
    super._update(from, to, value);
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `value`.
   */
  function transferByOwner(address from, address to, uint256 value) public virtual onlyOwner returns (bool) {
    _transfer(from, to, value);
    return true;
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev Destroys a `value` amount of tokens from the token holder 'owner'.
   *
   * See {ERC20-_burn}.
   */
  function burn(address owner, uint256 value) public virtual onlyOwner {
    _burn(owner, value);
  }
}
