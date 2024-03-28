// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

/**
 * @title
 * @author
 * @notice
 */
interface IZTT {
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
   * @notice fgbgf
   * @dev gfbfgb
   * @param owner fgb
   * @return sd sdsds
   */
  function transferAllowance(address owner) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice
   * @dev
   * @param from dsfdsf
   * @param to dsfdsf
   * @param value dsfdsf
   * @return bool asdasd
   */
  function transferByOwner(address from, address to, uint256 value) external returns (bool);

  /**
   * @notice
   * @dev
   * @param owner sdfdsfds
   */
  function approveTransfer(address owner, uint256 value) external;

  /**
   * @notice Mints new tokens
   * @dev Creates a `value` amount of tokens allocated to address 'to'.
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

  function rescueToken(IERC20 token, address beneficiary, uint256 value) external;

  function nonces(address owner) external view returns (uint256);
}
