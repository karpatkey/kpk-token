// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title
 * @author
 * @notice
 */
interface IkarpatkeyToken {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice
   * @dev Emitted when the transferAllowance for an `owner` is set by
   * a call to {approveTransfer}. `value` is the new transfer allowance.
   */
  event TransferApproval(address indexed sender, address indexed recipient, uint256 value);

  /**
   * @notice hhh
   * @dev hhh
   */
  event TransferAllowlisting(address indexed sender);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Tokens cannot be transferred to the token contract itself.
   * @dev
   */
  error TransferToTokenContract();

  error OwnerAlreadyAllowlisted(address sender);

  /**
   * @dev Indicates a failure with the caller's `transferAllowance`. Used in transfers.
   * @param owner Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param transferAllowance Amount of tokens the owner is allowed to transfer.
   * @param needed Minimum amount required to perform a transfer.
   */
  error InsufficientTransferAllowance(address owner, address recipient, uint256 transferAllowance, uint256 needed);

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
   * @param sender Address that may be allowed to transfer tokens.
   */
  error InvalidTransferAllowlisting(address sender);

  /**
   * @dev Indicates a failure with the `sender` or the `recipient` to be allowed to transfer tokens. Used in transfer approvals.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   */
  error InvalidTransferApproval(address sender, address recipient);

  /**
   * @dev
   * @param token sdf
   * @param value sdf
   * @param balance dsf
   */
  error InsufficientBalanceToRescue(IERC20 token, uint256 value, uint256 balance);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice dsds
   * @dev  sdsdsd
   * @param sender Address that may be allowed to transfer tokens.
   */
  function transferAllowlisted(address sender) external view returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `owner` will be
   * allowed to transfer through {transfer}, or through having a spender
   * account spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approveTransfer}, {transfer} or {transferFrom} are called.
   */
  function transferAllowance(address sender, address recipient) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Unpauses token transfers.
   * @dev Allows transfers of tokens. Can only be called by the token contract's owner.
   */
  function unpause() external;

  function transferAllowlist(address sender) external;

  /**
   * @notice Approves an account to transfer tokens when the contract is paused.
   * @dev Sets the transfer allowance for `owner` to `value`. Can only be called by the token contract's owner.
   * @param sender Address that may be allowed to transfer tokens.
   * @param recipient Address to which tokens may be transferred.
   * @param value Amount of tokens the owner is allowed to transfer.
   */
  function approveTransfer(address sender, address recipient, uint256 value) external;

  /**
   * @notice Mints new tokens.
   * @dev Creates a `value` amount of tokens allocated to address 'to'. Can only be called by the token contract's owner.
   *
   * See {ERC20-_mint}.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @notice Burns tokens
   * @dev Destroys a `value` amount of tokens held by the token holder 'owner'. Can only be called by the token contract's owner.
   *
   * See {ERC20-_burn}.
   */
  function burn(address owner, uint256 value) external;

  /**
   * @notice Transfers tokens held by token contract to a beneficiary.
   * @dev Transfers `value` amount of `token` held by the token contract to `beneficiary`. Can only be called by the token contract's owner.
   * @param token Address of the token to be transferred.
   * @param beneficiary Address to receive the tokens.
   * @param value Amount of tokens to be transferred.
   */
  function rescueToken(IERC20 token, address beneficiary, uint256 value) external returns (bool);
}
