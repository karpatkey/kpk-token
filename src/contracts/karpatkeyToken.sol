// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {
  ERC20PermitUpgradeable,
  NoncesUpgradeable
} from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC20VotesUpgradeable} from
  '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';

import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import {IERC20, IkarpatkeyToken} from 'interfaces/IkarpatkeyToken.sol';

contract karpatkeyToken is
  Initializable,
  IkarpatkeyToken,
  ERC20Upgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable
{
  mapping(address account => bool) private _transferAllowlisted;
  mapping(address account => mapping(address recipient => uint256)) private _transferAllowances;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner) public initializer {
    __ERC20_init('karpatkey Token', 'KPK');
    __ERC20Permit_init('karpatkey Token');
    __ERC20Votes_init();
    __Ownable_init(initialOwner);
    _mint(initialOwner, 1_000_000 * 10 ** decimals());
    _pause();
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowance(address sender, address recipient) public view virtual returns (uint256) {
    return _transferAllowances[sender][recipient];
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowlisted(address sender) public view virtual returns (bool) {
    return _transferAllowlisted[sender];
  }

  /// @inheritdoc IkarpatkeyToken
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowlist(address owner) public virtual onlyOwner {
    if (!paused()) {
      revert TransferAllowlistingWhenUnpaused();
    }
    _transferAllowlist(owner);
  }

  /// @inheritdoc IkarpatkeyToken
  function approveTransfer(address owner, address recipient, uint256 value) public virtual onlyOwner {
    if (!paused()) {
      revert TransferApprovalWhenUnpaused();
    }
    if (_transferAllowlisted[owner]) {
      revert OwnerAlreadyAllowlisted(owner);
    }
    _approveTransfer(owner, recipient, value);
  }

  /// @inheritdoc IkarpatkeyToken
  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  /// @inheritdoc IkarpatkeyToken
  function burn(address owner, uint256 value) public virtual onlyOwner {
    _burn(owner, value);
  }

  /// @inheritdoc IkarpatkeyToken
  function rescueToken(IERC20 token, address beneficiary, uint256 value) public virtual onlyOwner returns (bool) {
    _rescueToken(token, beneficiary, value);
    return true;
  }

  function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
    return super.nonces(owner);
  }

  function _transferAllowlist(address sender) internal virtual {
    if (sender == address(0)) {
      revert InvalidTransferAllowlisting(address(0));
    }
    _transferAllowlisted[sender] = true;
    emit TransferAllowlisting(sender);
  }

  function _approveTransfer(address sender, address recipient, uint256 value) internal virtual {
    if (sender == address(0) || recipient == address(0)) {
      revert InvalidTransferApproval(sender, recipient);
    }
    _transferAllowances[sender][recipient] = value;
    emit TransferApproval(sender, recipient, value);
  }

  function _update(address from, address to, uint256 value) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    if (to == address(this)) {
      revert TransferToTokenContract();
    }
    // 'from != owner()' is included to avoid involving the transfer allowance when tokens are transferred from the owner via {transferFrom}
    if (paused() && _msgSender() != owner() && from != owner() && !_transferAllowlisted[from]) {
      _spendTransferAllowance(from, to, value);
    }
    super._update(from, to, value);
  }

  /**
   * @dev Updates `owner` s transfer allowance based on spent `value`.
   *
   * Does not update the transfer allowance value in case of infinite allowance.
   * Reverts if not enough transfer allowance is available.
   *
   */
  function _spendTransferAllowance(address sender, address recipient, uint256 value) internal virtual {
    uint256 currentTransferAllowance = transferAllowance(sender, recipient);
    if (currentTransferAllowance != type(uint256).max) {
      if (currentTransferAllowance < value) {
        revert InsufficientTransferAllowance(sender, recipient, currentTransferAllowance, value);
      }
      unchecked {
        _approveTransfer(sender, recipient, currentTransferAllowance - value);
      }
    }
  }

  function _rescueToken(IERC20 token, address beneficiary, uint256 value) internal virtual {
    uint256 balance = token.balanceOf(address(this));
    if (balance < value) {
      revert InsufficientBalanceToRescue(token, value, balance);
    }
    token.transfer(beneficiary, value);
  }
}
