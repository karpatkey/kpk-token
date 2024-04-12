// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestDecreaseTransferAllowance is Base {
  address internal _sender = makeAddr('sender');
  address internal _recipient = makeAddr('recipient');
  address internal _randomAddress = makeAddr('randomAddress');
  uint256 internal _amount = 100;
  uint256 internal _amountDecrease = 50;

  event TransferApproval(address indexed _sender, address indexed _recipient, uint256 _value);

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, _recipient, _amount);
  }

  function testDecreaseTransferAllowance() public {
    bool _success;
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), _amount);
    vm.expectEmit(address(_kpktoken));
    emit TransferApproval(_sender, _recipient, _amount - _amountDecrease);
    _success = _kpktoken.decreaseTransferAllowance(_sender, _recipient, _amountDecrease);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), _amount - _amountDecrease);
    assertEq(_success, true);
  }

  function testDecreaseTransferAllowanceExpectedRevertOwner() public {
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.decreaseTransferAllowance(_randomAddress, _recipient, _amount);
  }

  function testDecreaseTransferAllowanceExpectedRevertBelowZero() public {
    vm.startPrank(_owner);
    vm.expectRevert(
      abi.encodeWithSelector(
        karpatkeyToken.DecreasedTransferAllowanceBelowZero.selector, _sender, _recipient, _amount, _amount + 1
      )
    );
    _kpktoken.decreaseTransferAllowance(_sender, _recipient, _amount + 1);
  }

  function testDecreaseTransferAllowanceExpectedRevertTransferApprovalWhenUnpaused() public {
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferApprovalWhenUnpaused.selector));
    _kpktoken.decreaseTransferAllowance(_sender, _recipient, _amount);
  }
}
