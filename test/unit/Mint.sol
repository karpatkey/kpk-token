// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract UnitTestMint is Base {
  function test_Mint() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.prank(_owner);
    _kpktoken.mint(_holder, _amount);
    assertEq(_kpktoken.balanceOf(_holder), _amount);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply + _amount);
  }

  function test_MintExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.mint(_holder, _amount);
  }
}
