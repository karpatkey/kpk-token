// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Upgrades} from '@openzeppelin/foundry-upgrades/src/Upgrades.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
import {Test} from 'forge-std/Test.sol';

abstract contract Base is Test {
  address internal _owner = makeAddr('owner');
  KpkToken internal _kpktoken;
  address internal _proxy;

  function setUp() public virtual {
    _proxy = Upgrades.deployTransparentProxy('KpkToken.sol', _owner, abi.encodeCall(KpkToken.initialize, _owner));
    _kpktoken = KpkToken(_proxy);
  }
}
