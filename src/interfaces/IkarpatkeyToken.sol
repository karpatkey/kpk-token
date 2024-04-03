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
  event TransferApproval(address indexed owner, uint256 value);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Tokens cannot be transferred to the token contract itself.
   * @dev
   */
  error TransferToTokenContract();

  /**
   * @dev Indicates a failure with the caller's `transferAllowance`. Used in transfers.
   * @param owner Address that may be allowed to transfer tokens.
   * @param transferAllowance Amount of tokens the owner is allowed to transfer.
   * @param needed Minimum amount required to perform a transfer.
   */
  error InsufficientTransferAllowance(address owner, uint256 transferAllowance, uint256 needed);

  /**
   * @notice
   * @dev
   */
  error TransferApprovalWhenUnpaused();

  /**
   * @dev Indicates a failure with the `owner` to be allowed to transfer tokens. Used in transfer approvals.
   * @param owner Address that may be allowed to transfer tokens.
   */
  error InvalidTransferApproval(address owner);

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
   * @dev Returns the remaining number of tokens that `owner` will be
   * allowed to transfer through {transfer}, or through having a spender
   * account spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approveTransfer}, {transfer} or {transferFrom} are called.
   */
  function transferAllowance(address owner) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Unpauses token transfers.
   * @dev Allows transfers of tokens. Can only be called by the token contract's owner.
   */
  function unpause() external;

  /**
   * @notice Approves an account to transfer tokens when the contract is paused.
   * @dev Sets the transfer allowance for `owner` to `value`. Can only be called by the token contract's owner.
   * @param owner Address that may be allowed to transfer tokens.
   * @param value Amount of tokens the owner is allowed to transfer.
   */
  function approveTransfer(address owner, uint256 value) external;

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
