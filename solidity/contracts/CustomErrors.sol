// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Custom Token Errors
 */
interface CustomErrors {
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
}
