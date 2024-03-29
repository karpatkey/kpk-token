// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {Upgrades} from 'openzeppelin-foundry-upgrades/Upgrades.sol';

abstract contract DeployToken is Script {
  function _deploy(address initialOwner) internal {
    vm.startBroadcast();
    Upgrades.deployTransparentProxy(
      'karpatkeyToken.sol', initialOwner, abi.encodeCall(karpatkeyToken.initialize, initialOwner)
    );
    vm.stopBroadcast();
  }
}

contract DeployTokenSepolia is DeployToken {
  function run() external {
    address initialOwner = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    _deploy(initialOwner);
  }
}
