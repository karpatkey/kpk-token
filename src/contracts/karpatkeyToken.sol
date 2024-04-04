// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {ERC20BurnableUpgradeable} from
  '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
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
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable
{
  mapping(address account => bool allowlisted) private _transferAllowlisted;
  mapping(address account => mapping(address recipient => uint256 amount)) private _transferAllowances;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _initialOwner) public initializer {
    __ERC20_init('karpatkey Token', 'KPK');
    __ERC20Burnable_init();
    __ERC20Permit_init('karpatkey Token');
    __ERC20Votes_init();
    __Ownable_init(_initialOwner);
    _mint(_initialOwner, 1_000_000 * 10 ** decimals());
    _pause();
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowance(address _sender, address _recipient) public view virtual returns (uint256 _value) {
    return _transferAllowances[_sender][_recipient];
  }

  /// @inheritdoc IkarpatkeyToken
  function transferAllowlisted(address _sender) public view virtual returns (bool _allowlisted) {
    return _transferAllowlisted[_sender];
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

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  /**
   * @notice Transfers tokens held by token contract to a beneficiary.
   * @dev Transfers `value` amount of `token` held by the token contract to `beneficiary`. Can only be called by the token contract's owner.
   * @param token Address of the token to be transferred.
   * @param beneficiary Address to receive the tokens.
   * @param value Amount of tokens to be transferred.
   */
  function rescueToken(
    IERC20 token,
    address beneficiary,
    uint256 value
  ) public virtual onlyOwner returns (bool success) {
    uint256 balance = token.balanceOf(address(this));
    if (balance < value) {
      revert InsufficientBalanceToRescue(token, value, balance);
    }
    token.transfer(beneficiary, value);
    return true;
  }

  function nonces(address owner)
    public
    view
    override(ERC20PermitUpgradeable, NoncesUpgradeable)
    returns (uint256 nonce)
  {
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
}
