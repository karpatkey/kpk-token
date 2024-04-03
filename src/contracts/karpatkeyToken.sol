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
  mapping(address account => uint256) private _transferAllowances;

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
  function pause() public onlyOwner {
    _pause();
  }

  /// @inheritdoc IkarpatkeyToken
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowance(address owner) public view virtual returns (uint256) {
    return _transferAllowances[owner];
  }

  /// @inheritdoc IkarpatkeyToken
  function approveTransfer(address owner, uint256 value) public virtual onlyOwner {
    if (!paused()) {
      revert TransferApprovalWhenUnpaused();
    }
    _approveTransfer(owner, value);
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

  function _approveTransfer(address owner, uint256 value) internal virtual {
    if (owner == address(0)) {
      revert InvalidTransferApproval(address(0));
    }
    _transferAllowances[owner] = value;
    emit TransferApproval(owner, value);
  }

  function _update(address from, address to, uint256 value) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    if (to == address(this)) {
      revert TransferToTokenContract();
    }
    // 'from != owner()' is included to avoid involving the transfer allowance when tokens are transferred from the owner via {transferFrom}
    if (paused() && _msgSender() != owner() && from != owner()) {
      _spendTransferAllowance(from, value);
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
  function _spendTransferAllowance(address owner, uint256 value) internal virtual {
    uint256 currentTransferAllowance = transferAllowance(owner);
    if (currentTransferAllowance != type(uint256).max) {
      if (currentTransferAllowance < value) {
        revert InsufficientTransferAllowance(owner, currentTransferAllowance, value);
      }
      unchecked {
        _approveTransfer(owner, currentTransferAllowance - value);
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
