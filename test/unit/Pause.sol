// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract UnitTestPause is Base {
  function testUnpauseExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.unpause();
  }

  function testUnpause() public {
    vm.prank(_owner);
    _kpktoken.unpause();
    assertEq(_kpktoken.paused(), false);
  }
}
