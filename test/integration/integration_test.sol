// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {Test} from 'forge-std/Test.sol';
import {Upgrades} from 'openzeppelin-foundry-upgrades/Upgrades.sol';

abstract contract Base is Test {
  address internal _owner = makeAddr('owner');
  karpatkeyToken internal _kpktoken;
  address internal _proxy;

  function setUp() public virtual {
    _proxy =
      Upgrades.deployTransparentProxy('karpatkeyToken.sol', _owner, abi.encodeCall(karpatkeyToken.initialize, _owner));
    _kpktoken = karpatkeyToken(_proxy);
  }
}

contract IntegrationTest is Base {
  function test_integration() public view {}
}
