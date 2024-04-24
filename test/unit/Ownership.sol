// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract UnitTestOwnership is Base {
  address internal _newOwner = makeAddr('newOwner');
  address internal _randomAddress = makeAddr('randomAddress');

  function testTransferOwnership() public {
    vm.prank(_owner);
    _kpktoken.transferOwnership(_newOwner);
    assertEq(_kpktoken.owner(), _newOwner);
  }

  function testTransferOwnershipExpectedRevertOwner() public {
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferOwnership(_newOwner);
  }

  function testRennounceOwnership() public {
    vm.prank(_owner);
    _kpktoken.renounceOwnership();
    assertEq(_kpktoken.owner(), address(0));
  }

  function test_rennounceOwnershipExpectedRevertOwner() public {
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.renounceOwnership();
  }
}
