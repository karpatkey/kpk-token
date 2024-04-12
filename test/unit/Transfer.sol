// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestTransfer is Base {
  address internal _sender = makeAddr('sender');
  address internal _recipient = makeAddr('recipient');
  uint256 internal _amount = 100;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.transfer(_sender, _amount);
  }

  function testTransferOwner() public {
    vm.startPrank(_owner);
    bool _result = _kpktoken.transfer(_recipient, _amount);
    assertEq(_result, true);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_owner), _kpktoken.totalSupply() - 2 * _amount);
  }

  function testTransferExpectedRevertInsufficientTransferAllowance() public {
    vm.startPrank(_sender);
    vm.expectRevert(
      abi.encodeWithSelector(karpatkeyToken.InsufficientTransferAllowance.selector, _sender, _recipient, 0, _amount)
    );
    _kpktoken.transfer(_recipient, _amount);
  }

  function testTransfer() public {
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, _recipient, _amount + 1);
    vm.startPrank(_sender);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_sender), 0);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 1);
  }

  function testTransferInfiniteTransferAllowance() public {
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, _recipient, type(uint256).max);
    vm.startPrank(_sender);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_sender), 0);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), type(uint256).max);
  }

  function testTransferExpectedRevertTransferToTokenContract() public {
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, _recipient, _amount + 1);
    vm.startPrank(_sender);
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferToTokenContract.selector));
    _kpktoken.transfer(address(_kpktoken), _amount);
  }

  function testTransferWhenUnpaused() public {
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_sender);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_sender), 0);
  }
}
