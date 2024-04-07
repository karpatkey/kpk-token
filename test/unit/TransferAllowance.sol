// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestTransferAllowance is Base {
  event TransferApproval(address indexed _sender, address indexed _recipient, uint256 _value);

  function testTransferAllowance() public {
    address _sender = makeAddr('sender');
    address _recipient = makeAddr('recipient');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 0);
    vm.expectEmit(address(_kpktoken));
    emit TransferApproval(_sender, _recipient, _amount);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), _amount);
  }

  function testTransferAllowanceExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _recipient = makeAddr('recipient');
    uint256 _amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.approveTransfer(_randomAddress, _recipient, _amount);
  }

  function testTransferAllowanceExpectedRevertTransferApprovalWhenUnpaused() public {
    uint256 _amount = 100;
    address _sender = makeAddr('sender');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferApprovalWhenUnpaused.selector));
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
  }
}
