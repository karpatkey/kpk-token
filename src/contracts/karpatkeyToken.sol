// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ERC20Upgradeable, IERC20} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {ERC20BurnableUpgradeable} from
  '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import {
  ERC20PermitUpgradeable,
  NoncesUpgradeable
} from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {ERC20VotesUpgradeable} from
  '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';

import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';

contract karpatkeyToken is
  Initializable,
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

  /**
   * @notice Indicates the granting of unrestricted permission to an address to transfer and/or burn tokens when the contract is paused.
   * @dev Emmited when an address is added to the transfer allowlist by a call to {transferAllowlist}.
   * @param _sender Address that is allowlisted to transfer and/or burn tokens.
   */
  event TransferAllowlisting(address indexed _sender);

  /**
   * @notice Indicates the setting of a transfer allowance for an address to transfer tokens to a specified recipient when the contract is paused.
   * @dev Emitted when the transferAllowance for an `owner` is set by a call to {approveTransfer}. `value` is the new transfer allowance.
   */
  event TransferApproval(address indexed _sender, address indexed _recipient, uint256 _value);

  /**
   * @notice Tokens cannot be transferred to the token contract itself.
   * @dev Thrown when an attempt is made to transfer tokens to the token contract itself.
   */
  error TransferToTokenContract();

  /**
   * @notice Tokens cannot be transferred to the token contract itself.
   * @dev Thrown when an attempt is made to transfer tokens to the token contract itself.
   */
  error OwnerAlreadyAllowlisted(address _sender);

  /**
   * @dev Indicates a failure with the caller's `transferAllowance`. Used in transfers.
   * @param _owner Address that may be allowed to transfer tokens.
   * @param _recipient Address to which tokens may be transferred.
   * @param _transferAllowance Amount of tokens the owner is allowed to transfer to the recipient.
   * @param _needed Minimum amount required to perform a transfer.
   */
  error InsufficientTransferAllowance(address _owner, address _recipient, uint256 _transferAllowance, uint256 _needed);

  /**
   * @notice
   * @dev
   */
  error TransferAllowlistingWhenUnpaused();

  /**
   * @notice
   * @dev
   */
  error TransferApprovalWhenUnpaused();

  /**
   * @dev
   * @param _sender Address that may be allowed to transfer tokens.
   */
  error InvalidTransferAllowlisting(address _sender);

  /**
   * @dev Indicates a failure with the `sender` or the `recipient` to be allowed to transfer tokens. Used in transfer approvals.
   * @param _sender Address that may be allowed to transfer tokens.
   * @param _recipient Address to which tokens may be transferred.
   */
  error InvalidTransferApproval(address _sender, address _recipient);

  /**
   * @notice
   * @dev
   * @param _token sdf
   * @param _value sdf
   * @param _balance dsf
   */
  error InsufficientBalanceToRescue(IERC20 _token, uint256 _value, uint256 _balance);

  /**
   * @notice dsds
   * @dev  sdsdsd
   * @param _sender Address that may be allowed to transfer tokens.
   */
  function transferAllowlisted(address _sender) public view virtual returns (bool _allowlisted) {
    return _transferAllowlisted[_sender];
  }

  /**
   * @dev Returns the remaining number of tokens that `owner` will be
   * allowed to transfer through {transfer}, or through having a spender
   * account spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approveTransfer}, {transfer} or {transferFrom} are called.
   */
  function transferAllowance(address _sender, address _recipient) public view virtual returns (uint256 _value) {
    return _transferAllowances[_sender][_recipient];
  }

  /**
   * @notice Unpauses token transfers.
   * @dev Allows transfers and burning of tokens. Can only be called by the token contract's owner.
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @notice Grants unrestricted permission to an address to transfer and/or burn tokens.
   * @dev Allowlists `_owner` so that it can transfer and/or burn tokens. Can only be called by the token contract's owner.
   * @param _owner Address that is allowlisted to transfer and/or burn tokens.
   */
  function transferAllowlist(address _owner) public virtual onlyOwner {
    if (!paused()) {
      revert TransferAllowlistingWhenUnpaused();
    }
    _transferAllowlist(_owner);
  }

  /**
   * @notice Approves an account to transfer tokens when the contract is paused.
   * @dev Sets the transfer allowance for `owner` to `value` for. Can only be called by the token contract's owner.
   * @param _sender Address that may be allowed to transfer tokens.
   * @param _recipient Address to which tokens may be transferred.
   * @param _value Maximum amount of tokens the owner is allowed to transfer.
   */
  function approveTransfer(address _sender, address _recipient, uint256 _value) public virtual onlyOwner {
    if (!paused()) {
      revert TransferApprovalWhenUnpaused();
    }
    if (_transferAllowlisted[_sender]) {
      revert OwnerAlreadyAllowlisted(_sender);
    }
    _approveTransfer(_sender, _recipient, _value);
  }

  /**
   * @notice Mints new tokens.
   * @dev Creates a `_amount` amount of tokens and assigns them to `_to`, by transferring it from address(0). Can only be called
   * by the token contract's owner. See {ERC20Upgradeable-_mint}.
   * @param _to Address to receive the tokens.
   * @param _amount Amount of tokens to be minted.
   */
  function mint(address _to, uint256 _amount) public onlyOwner {
    _mint(_to, _amount);
  }

  /**
   * @notice Transfers tokens held by the token contract to a recipient.
   * @dev Transfers `value` amount of `token` held by the token contract to `_recipient`. Can only be called by the token contract's owner.
   * @param _token Address of the token to be transferred.
   * @param _recipient Address to receive the tokens.
   * @param _value Amount of tokens to be transferred.
   */
  function rescueToken(IERC20 _token, address _recipient, uint256 _value) public onlyOwner returns (bool _success) {
    uint256 _balance = _token.balanceOf(address(this));
    if (_balance < _value) {
      revert InsufficientBalanceToRescue(_token, _value, _balance);
    }
    _token.transfer(_recipient, _value);
    return true;
  }

  /**
   * @notice Returns the next unused nonce for an address.
   * @dev
   */
  function nonces(address _owner)
    public
    view
    override(ERC20PermitUpgradeable, NoncesUpgradeable)
    returns (uint256 _nonce)
  {
    return super.nonces(_owner);
  }

  function _transferAllowlist(address _sender) internal virtual {
    if (_sender == address(0)) {
      revert InvalidTransferAllowlisting(address(0));
    }
    _transferAllowlisted[_sender] = true;
    emit TransferAllowlisting(_sender);
  }

  function _approveTransfer(address _sender, address _recipient, uint256 _value) internal virtual {
    if (_sender == address(0) || _recipient == address(0)) {
      revert InvalidTransferApproval(_sender, _recipient);
    }
    _transferAllowances[_sender][_recipient] = _value;
    emit TransferApproval(_sender, _recipient, _value);
  }

  function _update(
    address _from,
    address _to,
    uint256 _value
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    if (_to == address(this)) {
      revert TransferToTokenContract();
    }
    // 'from != owner()' is included to avoid involving the transfer allowance when tokens are transferred from the owner via {transferFrom}
    if (paused() && _msgSender() != owner() && _from != owner() && !_transferAllowlisted[_from]) {
      _spendTransferAllowance(_from, _to, _value);
    }
    super._update(_from, _to, _value);
  }

  /**
   * @dev Updates `owner` s transfer allowance based on spent `value`.
   *
   * Does not update the transfer allowance value in case of infinite allowance.
   * Reverts if not enough transfer allowance is available.
   *
   */
  function _spendTransferAllowance(address _sender, address _recipient, uint256 _value) internal virtual {
    uint256 _currentTransferAllowance = transferAllowance(_sender, _recipient);
    if (_currentTransferAllowance != type(uint256).max) {
      if (_currentTransferAllowance < _value) {
        revert InsufficientTransferAllowance(_sender, _recipient, _currentTransferAllowance, _value);
      }
      unchecked {
        _approveTransfer(_sender, _recipient, _currentTransferAllowance - _value);
      }
    }
  }
}
