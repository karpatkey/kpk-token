// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract UnitTestOwnership is Base {
  function test_transferOwnership() public {
    address _newOwner = makeAddr('newOwner');
    vm.prank(_owner);
    _kpktoken.transferOwnership(_newOwner);
    assertEq(_kpktoken.owner(), _newOwner);
  }

  function test_transferOwnershipExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _newOwner = makeAddr('newOwner');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferOwnership(_newOwner);
  }

  function test_rennounceOwnership() public {
    vm.prank(_owner);
    _kpktoken.renounceOwnership();
    assertEq(_kpktoken.owner(), address(0));
  }

  function test_rennounceOwnershipExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.renounceOwnership();
  }
}
