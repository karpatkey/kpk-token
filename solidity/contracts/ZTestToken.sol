// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';

contract ZTestToken is ERC20, Pausable, Ownable, ERC20Permit, ERC20Votes {
  constructor(address initialOwner) ERC20('ZTest Token', 'ZTT') Ownable(initialOwner) ERC20Permit('ZTest Token') {
    _mint(msg.sender, 1_000_000 * 10 ** decimals());
    _pause();
  }

  /**
   * @dev Tokens cannot be transferred to the token contract itself.
   */
  error TransferToTokenContract();

  /**
   * @dev Indicates a failure with the caller's `transferAllowance`. Used in transfers.
   * @param owner Address that may be allowed to transfer tokens.
   * @param transferAllowance Amount of tokens a the owner is allowed to transfer.
   * @param needed Minimum amount required to perform a transfer.
   */
  error InsufficientTransferAllowance(address owner, uint256 transferAllowance, uint256 needed);

  error InvalidTransferApproval(address owner);

  error NotEnoughBalanceToRescue(IERC20 token, address beneficiary, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event TransferApproval(address indexed owner, uint256 value);

  mapping(address account => uint256) private _transferAllowances;

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
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

  function transferAllowance(address owner) public view virtual returns (uint256) {
    return _transferAllowances[owner];
  }

  /**
   * @dev Destroys a `value` amount of tokens from the token holder 'owner'.
   *
   * See {ERC20-_burn}.
   */
  function approveTransfer(address owner, uint256 value) public virtual onlyOwner {
    _approveTransfer(owner, value);
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

  function rescueToken(IERC20 token, address beneficiary, uint256 value) public virtual onlyOwner {
    _rescueToken(token, beneficiary, value);
  }

  function _approveTransfer(address owner, uint256 value) internal virtual {
    if (owner == address(0)) {
      revert InvalidTransferApproval(address(0));
    }
    _transferAllowances[owner] = value;
    emit TransferApproval(owner, value);
  }

  function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
    if (to == address(this)) {
      revert TransferToTokenContract();
    }
    uint256 allowance = transferAllowance(from);
    if (paused() && owner() != _msgSender() && allowance < value) {
      revert InsufficientTransferAllowance(from, allowance, value);
    }
    super._update(from, to, value);
  }

  /**
   * @dev Updates `owner` s transfer allowance based on spent `value`.
   *
   * Does not update the transferAllowance value in case of infinite allowance.
   * Revert if not enough transfer allowance is available.
   *
   * Does not emit an {Approval} event.
   */
  function _spendTransferAllowance(address owner, uint256 value) internal virtual {
    uint256 currentTransferAllowance = transferAllowance(owner);
    if (currentTransferAllowance != type(uint256).max) {
      if (currentTransferAllowance < value) {
        revert InsufficientTransferAllowance(owner, currentTransferAllowance, value);
      }
      unchecked {
        _approve(owner, owner, currentTransferAllowance - value, false);
      }
    }
  }

  function _rescueToken(IERC20 token, address beneficiary, uint256 value) internal virtual {
    uint256 balance = token.balanceOf(address(this));
    if (balance < value) {
      revert NotEnoughBalanceToRescue(token, beneficiary, value);
    }
    token.transfer(beneficiary, value);
  }

  function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
    return super.nonces(owner);
  }
}
