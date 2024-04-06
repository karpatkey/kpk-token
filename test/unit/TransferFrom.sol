// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';

import {Base} from '.././Base.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestTransferFrom is Base {
  address internal _sender = makeAddr('sender');
  address internal _mover = makeAddr('mover');
  address internal _recipient = makeAddr('recipient');
  uint256 internal _amount = 100;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.transfer(_sender, _amount);
  }

  function test_transferFromOwner() public {
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_owner, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_owner), _kpktoken.totalSupply() - 2 * _amount + 1);
  }

  function test_transferFromOwnerExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount, _amount + 1)
    );
    _kpktoken.transferFrom(_owner, _recipient, _amount + 1);
  }

  function test_transferFromTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_sender, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
  }

  function test_transferFromInfiniteTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, type(uint256).max);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_sender, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), type(uint256).max);
  }

  function test_transferFromExpectedRevertInsufficientTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount + 1);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(
        karpatkeyToken.InsufficientTransferAllowance.selector, _sender, _recipient, _amount, _amount + 1
      )
    );
    _kpktoken.transferFrom(_sender, _recipient, _amount + 1);
  }

  function test_transferFromExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.transferFrom(_sender, _recipient, _amount);
  }

  function test_transferFromTransferAllowlist() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_sender, true);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_sender, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
  }

  function test_transferFromTransferAllowlistExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_sender, true);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.transferFrom(_sender, _recipient, _amount);
  }

  function test_transferFromWhenUnpaused() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_sender, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
  }

  function test_transferFromWhenUnpausedExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.transferFrom(_sender, _recipient, _amount);
  }
}
