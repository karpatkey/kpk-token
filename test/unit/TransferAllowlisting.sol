// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

contract UnitTestTransferAllowlisting is Base {
  function testTransferAllowlist() public {
    address _sender = makeAddr('sender');
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowlisted(_sender), false);
    _kpktoken.transferAllowlist(_sender, true);
    assertEq(_kpktoken.transferAllowlisted(_sender), true);
    _kpktoken.transferAllowlist(_sender, false);
    assertEq(_kpktoken.transferAllowlisted(_sender), false);
  }

  function testTransferAllowlistExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferAllowlist(_randomAddress, true);
  }

  function testTransferAllowlistExpectedRevertTransferAllowlistingWhenUnpaused() public {
    address _sender = makeAddr('sender');
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(KpkToken.TransferAllowlistingWhenUnpaused.selector));
    _kpktoken.transferAllowlist(_sender, true);
    vm.expectRevert(abi.encodeWithSelector(KpkToken.TransferAllowlistingWhenUnpaused.selector));
    _kpktoken.transferAllowlist(_sender, false);
  }
}
