// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ISafeCreateCall, SAFE_CREATE_CALL} from 'contracts/KpkDeployerLib.sol';
import {Test, console} from 'forge-std/Test.sol';

contract ForkTest is Test {
  uint256 fork;
  /// @dev set BASE_RPC_URL in .env to run mainnet tests
  string RPC_URL = vm.envString('MAINNET_RPC');
  /// @dev The address of the Safe Create Call on Mainnet
  ISafeCreateCall safeCreateCall = ISafeCreateCall(SAFE_CREATE_CALL);

  function _forkSetupBefore() public {
    fork = vm.createFork(RPC_URL);
    vm.selectFork(fork);
  }
}

contract ForkTestSepolia is Test {
  uint256 fork;
  /// @dev set BASE_RPC_URL in .env to run mainnet tests
  string RPC_URL = vm.envString('SEPOLIA_RPC');
  /// @dev The address of the Safe Create Call on Sepolia
  ISafeCreateCall safeCreateCall = ISafeCreateCall(SAFE_CREATE_CALL);

  function _forkSetupBefore() public {
    fork = vm.createFork(RPC_URL);
    vm.selectFork(fork);
  }
}
