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
   * @dev Emitted when the transferAllowance of for an `owner` is set by
   * a call to {approveTransfer}. `value` is the new allowance.
   */
  event TransferApproval(address indexed owner, uint256 value);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/
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

  /**
   * @dev
   * @param owner
   */
  error InvalidTransferApproval(address owner);

  /**
   * @dev
   * @param owner
   */
  error NotEnoughBalanceToRescue(IERC20 token, address beneficiary, uint256 value);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function transferAllowance(address owner) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function transferByOwner(address from, address to, uint256 value) external returns (bool);

  function approveTransfer(address owner, uint256 value) external;

  /**
   * @notice Mints new tokens
   * @dev Creates a `value` amount of tokens allocated to address 'to'.
   *
   * See {ERC20-_mint}.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @dev Destroys a `value` amount of tokens from the token holder 'owner'.
   *
   * See {ERC20-_burn}.
   */
  function burn(address owner, uint256 value) external;

  function rescueToken(IERC20 token, address beneficiary, uint256 value) external;

  function nonces(address owner) external view returns (uint256);
}
