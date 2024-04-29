// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity =0.8.20;

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
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title karpatkey Token Contract
 * @author karpatkey developers
 * @notice karpatkey's governance token.
 */
contract karpatkeyToken is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable
{
  using SafeERC20 for IERC20;

  mapping(address account => bool allowlisted) private _transferAllowlisted;
  mapping(address account => mapping(address recipient => uint256 amount)) private _transferAllowances;

  /**
   * @notice Indicates the granting or cancelling of unrestricted permission to an address to transfer tokens
   * when the contract is paused.
   * @dev Emmited when an address is added to or removed from the transfer allowlist by a call to
   * {transferAllowlist}.
   * @param sender Address that is allowlisted to transfer tokens.
   * @param allowlisted Boolean indicating whether `sender` has been allowlisted or removed from the
   * allowlist.
   */
  event TransferAllowlisting(address indexed sender, bool indexed allowlisted);

  /**
   * @notice Indicates the setting of a transfer allowance for an address to transfer tokens to a specified
   * recipient when the contract is paused.
   * @dev Emitted when the transfer allowance for a `sender` for `recipient` is set by a call to
   *  {approveTransfer}. `value` is the new transfer allowance.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param value New transfer allowance; maximum amount of tokens `sender` is allowed to transfer to `recipient`.
   */
  event TransferApproval(address indexed sender, address indexed recipient, uint256 value);

  /**
   * @notice KPK tokens cannot be transferred to the KPK token contract itself.
   * @dev Thrown when {transfer} and {transferFrom} are called with the token contract's address as the
   */
  error TransferToTokenContract();

  /**
   * @notice Indicates a failure with the caller's transfer allowance for the specified recipient.
   * @dev Thrown by {_spendTransferAllowance} when {transfer}, {transferFrom}, {burn} or {burnFrom} are called
   * and transfer allowance for `sender` for `recipient` is insufficient to perform a transfer.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens are intended to be transferred.
   * @param _currentTransferAllowance Maximum amount of tokens `sender` is allowed to transfer to `recipient`.
   * @param needed Minimum transfer allowance required to perform the transfer.
   */
  error InsufficientTransferAllowance(
    address sender, address recipient, uint256 _currentTransferAllowance, uint256 needed
  );

  /**
   * @notice Indicates that the contract is unpaused when a transfer allowlisting is attempted.
   * @dev Thrown when {transferAllowlist} is called when the contract is unpaused.
   */
  error TransferAllowlistingWhenUnpaused();

  /**
   * @notice Indicates that the contract is unpaused when a transfer approval is attempted.
   * @dev Thrown when {approveTransfer} is called when the contract is unpaused.
   */
  error TransferApprovalWhenUnpaused();

  /**
   * @notice Indicates a failure with the `sender` to be allowlisted to transfer tokens.
   * @dev Throws when {transferAllowlist} is called with the zero address as `sender`.
   * @param sender Address to be allowlisted to transfer tokens.
   */
  error InvalidTransferAllowlisting(address sender);

  /**
   * @notice Indicates a failure with the `sender` to be allowed to transfer tokens.
   * @dev Throws when {approveTransfer} is called with the zero address as `sender`.
   * @param sender Address that may be allowed to transfer tokens.
   */
  error InvalidTransferApproval(address sender);

  /**
   * @notice Indicates that the token contract does not have enough balance of the token to be rescued.
   * @dev Thrown when {rescueToken} is called attempting to transfer a higher amount of the token to be
   * rescued than the token contract's balance.
   * @param token Address of the token to be transferred.
   * @param balance Token contract's balance of `token`.
   * @param value Amount of tokens to be transferred.
   */
  error InsufficientBalanceToRescue(IERC20 token, uint256 balance, uint256 value);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner) public initializer {
    __ERC20_init('karpatkey Token', 'KPK');
    __ERC20Burnable_init();
    __ERC20Permit_init('karpatkey Token');
    __ERC20Votes_init();
    __Ownable_init(initialOwner);
    _mint(initialOwner, 1_000_000 * 10 ** decimals());
    _pause();
  }

  /**
   * @notice Unpauses token transfers.
   * @dev Allows transfers of tokens. Can only be called by the token contract's owner. Renders
   * {transferAllowlist} and {approveTransfer} obsolete.
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @notice Grants or cancels unrestricted permission to an address to transfer tokens when the contract
   * is paused.
   * @dev Allowlists `_owner` so that it can transfer tokens via {transfer}, {transferFrom}, {burn} and
   * {burnFrom}. Can only be called by the token contract's owner.
   * Emits a {TransferAllowlisting} event.
   * Reverts with {TransferAllowlistingWhenUnpaused} if called when the contract is unpaused.
   * Reverts with {InvalidTransferAllowlisting} if `sender` is the zero address.
   * @param sender Address that is allowlisted to transfer tokens.
   * @param allowlisted Boolean indicating whether `sender` is allowlisted.
   */
  function transferAllowlist(address sender, bool allowlisted) public onlyOwner {
    if (!paused()) {
      revert TransferAllowlistingWhenUnpaused();
    }
    if (sender == address(0)) {
      revert InvalidTransferAllowlisting(address(0));
    }
    _transferAllowlisted[sender] = allowlisted;
    emit TransferAllowlisting(sender, allowlisted);
  }

  /**
   * @notice Increases the transfer allowance for an account to transfer tokens to a specified recipient
   * when the contract is paused.
   * @dev Increases the transfer allowance for `sender` and `recipient` by `addedValue`. Can only be called by the
   * token contract's owner.
   * Reverts with {TransferApprovalWhenUnpaused} if called when the contract is unpaused.
   * See {_approveTransfer}.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param addedValue Amount to increase the transfer allowance by.
   */
  function increaseTransferAllowance(
    address sender,
    address recipient,
    uint256 addedValue
  ) public onlyOwner returns (bool success) {
    if (!paused()) {
      revert TransferApprovalWhenUnpaused();
    }
    _approveTransfer(sender, recipient, _transferAllowances[sender][recipient] + addedValue);
    return true;
  }

  /**
   * @notice Decreases the transfer allowance for an account to transfer tokens to a specified recipient
   * when the contract is paused.
   * @dev Decreases the transfer allowance for `sender` and `recipient` by `subtractedValue`. If
   * `subtractedValue` is larger than or equal to the current transfer allowance, then the transfer allowance is set to
   * 0. Can only be called by the token contract's owner.
   * Reverts with {TransferApprovalWhenUnpaused} if called when the contract is unpaused.
   * See {_approveTransfer}.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param subtractedValue Amount to decrease the transfer allowance by.
   */
  function decreaseTransferAllowance(
    address sender,
    address recipient,
    uint256 subtractedValue
  ) public onlyOwner returns (bool success) {
    if (!paused()) {
      revert TransferApprovalWhenUnpaused();
    }
    uint256 currentTransferAllowance = _transferAllowances[sender][recipient];
    if (currentTransferAllowance <= subtractedValue) {
      _approveTransfer(sender, recipient, 0);
    } else {
      unchecked {
        // Overflow not possible: subtractedValue < currentTransferAllowance.
        _approveTransfer(sender, recipient, currentTransferAllowance - subtractedValue);
      }
    }
    return true;
  }

  /**
   * @notice Mints new tokens.
   * @dev Creates a `amount` amount of tokens and assigns them to `to`, by transferring it from address(0).
   * Can only be called by the token contract's owner.
   * See {ERC20Upgradeable-_mint}.
   * @param to Address to receive the tokens.
   * @param amount Amount of tokens to be minted.
   */
  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  /**
   * @notice Transfers tokens held by the token contract to a recipient. Meant for tokens that have been
   * unintentionally sent to the contract.
   * @dev Transfers `value` amount of `token` held by the contract to `recipient`. Can only be called by the
   * contract's owner.
   * Reverts with {InsufficientBalanceToRescue} if the contract's balance of `token` is less than `value`.
   * @param token Address of the token to be transferred.
   * @param recipient Address to receive the tokens.
   * @param value Amount of tokens to be transferred.
   * @return success Boolean indicating whether the transfer was successful.
   */
  function rescueToken(IERC20 token, address recipient, uint256 value) public onlyOwner returns (bool success) {
    uint256 balance = token.balanceOf(address(this));
    if (balance < value) {
      revert InsufficientBalanceToRescue(token, balance, value);
    }
    token.safeTransfer(recipient, value);
    return true;
  }

  /**
   * @notice Indicates whether an address is allowlisted to transfer tokens when the contract is paused.
   * @dev  Returns `true` if `sender` has been allowlisted to transfer tokens by a call to
   * {transferAllowlist}, otherwise `false`. This is `false` by default.
   * This value changes when {transferAllowlist} is called.
   * @param sender Address to check if it is allowlisted to transfer tokens.
   * @return allowlisted Boolean indicating whether `sender` is allowlisted.
   */
  function transferAllowlisted(address sender) public view returns (bool allowlisted) {
    return _transferAllowlisted[sender];
  }

  /**
   * @notice Returns the remaining number of tokens that `sender` is allowed to transfer to `recipient`.
   * @dev Returns the remaining number of tokens that `sender` is allowed to transfer to `recipient` by a call to
   * {transfer} or by a call to {burn} (with `recipient` being the zero address), or by having a spender call
   * {transferFrom} or {burnFrom} (with `recipient` being the zero address). This is zero by default.
   * This value changes when {approveTransfer}, {transfer}, {transferFrom} are called, or when {burn} and {burnFrom}
   * are called if `recipient` is the zero address.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @return value Maximum amount of tokens the owner is allowed to transfer.
   */
  function transferAllowance(address sender, address recipient) public view returns (uint256 value) {
    return _transferAllowances[sender][recipient];
  }

  /**
   * @notice Returns the next unused nonce for an address.
   * @dev See {NoncesUpgradeable-nonces}.
   */
  function nonces(address owner)
    public
    view
    override(ERC20PermitUpgradeable, NoncesUpgradeable)
    returns (uint256 nonce)
  {
    return super.nonces(owner);
  }

  /**
   * @dev Sets the transfer allowance for `sender` and `recipient` to `value`.
   * Emits a {TransferApproval} event.
   * Reverts with {InvalidTransferApproval} if `sender` is the zero address.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param value Maximum amount of tokens the owner is allowed to transfer.
   */
  function _approveTransfer(address sender, address recipient, uint256 value) internal {
    if (sender == address(0)) {
      revert InvalidTransferApproval(address(0));
    }
    _transferAllowances[sender][recipient] = value;
    emit TransferApproval(sender, recipient, value);
  }

  /**
   * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
   * (or `to`) is the zero address. If the contract is paused and the caller is not the contract's owner, and
   * additionally if `from` is not the contract's owner and `from` is not allowlisted to transfer tokens, then
   * `value` is spent from the transfer allowance for `from` to `to`.
   * Reverts with {TransferToTokenContract} if `to` is the token contract itself.
   * See {ERC20Upgradeable-_update}
   * @param from Address to transfer tokens from.
   * @param to Address to transfer tokens to.
   * @param value Amount of tokens to be transferred.
   */
  function _update(address from, address to, uint256 value) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    if (to == address(this)) {
      revert TransferToTokenContract();
    }
    // 'from != owner()' is included to avoid involving the transfer allowance mechanism when tokens are
    // transferred from the owner via {transferFrom}
    if (paused() && _msgSender() != owner() && from != owner() && !_transferAllowlisted[from]) {
      _spendTransferAllowance(from, to, value);
    }
    super._update(from, to, value);
  }

  /**
   * @dev Updates `sender`'s transfer allowance to transfer to `recipient` based on spent `value`.
   * Does not update the transfer allowance value in case of infinite transfer allowance.
   * Reverts with {InsufficientTransferAllowance} if not enough transfer allowance is available.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param value Amount to be spent from the transfer allowance.
   */
  function _spendTransferAllowance(address sender, address recipient, uint256 value) internal {
    uint256 _currentTransferAllowance = transferAllowance(sender, recipient);
    if (_currentTransferAllowance != type(uint256).max) {
      if (_currentTransferAllowance < value) {
        revert InsufficientTransferAllowance(sender, recipient, _currentTransferAllowance, value);
      }
      unchecked {
        _approveTransfer(sender, recipient, _currentTransferAllowance - value);
      }
    }
  }
}
