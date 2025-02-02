// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Upgrades} from '@openzeppelin/foundry-upgrades/src/Upgrades.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
import {Script} from 'forge-std/Script.sol';

abstract contract DeployToken is Script {
  function _deploy(
    address _initialOwner
  ) internal {
    vm.startBroadcast();
    Upgrades.deployTransparentProxy('kpkToken.sol', _initialOwner, abi.encodeCall(KpkToken.initialize, _initialOwner));
    vm.stopBroadcast();
  }
}

contract DeployTokenSepolia is DeployToken {
  function run() external {
    address _initialOwner = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    _deploy(_initialOwner);
  }
}
