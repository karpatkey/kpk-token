// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestIncreaseTransferAllowance is Base {
  uint256 internal _amount = 100;
  address internal _sender = makeAddr('sender');
  address internal _recipient = makeAddr('recipient');
  address internal _randomAddress = makeAddr('randomAddress');

  event TransferApproval(address indexed _sender, address indexed _recipient, uint256 _value);

  function testIncreaseTransferAllowance() public {
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 0);
    vm.expectEmit(address(_kpktoken));
    emit TransferApproval(_sender, _recipient, _amount);
    _kpktoken.increaseTransferAllowance(_sender, _recipient, _amount);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), _amount);
  }

  function testIncreaseTransferAllowanceExpectedRevertOwner() public {
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.increaseTransferAllowance(_randomAddress, _recipient, _amount);
  }

  function testIncreaseTransferAllowanceExpectedRevertTransferApprovalWhenUnpaused() public {
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferApprovalWhenUnpaused.selector));
    _kpktoken.increaseTransferAllowance(_sender, _recipient, _amount);
  }
}
