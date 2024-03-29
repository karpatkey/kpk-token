// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {console} from 'forge-std/console.sol';

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {Script} from 'forge-std/Script.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

abstract contract DeployToken is Script {
  function _deploy(address initialOwner) internal {
    vm.startBroadcast();
    new karpatkeyToken(initialOwner);
    vm.stopBroadcast();
  }
}

contract DeployTokenSepolia is DeployToken {
  function run() external {
    address initialOwner = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    _deploy(initialOwner);
  }
}

contract DeployTimelock is Script {
  function _deploy(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin) internal {
    vm.startBroadcast();
    console.log('This is super dope');
    TimelockController timelock = new TimelockController(minDelay, proposers, executors, admin);
    console.log('This is dope', address(timelock));
    vm.stopBroadcast();
  }
}

contract DeployTimelockSepolia is DeployTimelock {
  function run() external {
    uint256 minDelay = 1 * 60;
    address[] memory proposers = new address[](1);
    proposers[0] = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    address[] memory executors = new address[](1);
    executors[0] = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    address admin = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    _deploy(minDelay, proposers, executors, admin);
  }
}
