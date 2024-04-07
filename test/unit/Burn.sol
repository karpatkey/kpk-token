// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestBurn is Base {
  address internal _holder = makeAddr('holder');
  uint256 internal _amount = 100;
  uint256 internal _amountToMint = 150;
  uint256 internal _initialTotalSupply;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amountToMint);
    _initialTotalSupply = _kpktoken.totalSupply();
  }

  function testBurnOwner() public {
    uint256 _initialBalance = _kpktoken.balanceOf(_owner);
    vm.startPrank(_owner);
    _kpktoken.burn(_amount);
    assertEq(_kpktoken.balanceOf(_owner), _initialBalance - _amount);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount);
  }

  function testBurnAllowlisted() public {
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_holder, true);
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), _amountToMint - _amount + 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnTransferAllowance() public {
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_holder, address(0), _amount);
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), _amountToMint - _amount + 1);
    assertEq(_kpktoken.transferAllowance(_holder, address(0)), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnExpectedRevertERC20InsufficientBalance() public {
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_holder, true);
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, _holder, _amountToMint, _amountToMint + 1)
    );
    _kpktoken.burn(_amountToMint + 1);
  }

  function testBurnExpectedRevertInsufficientTransferAllowance() public {
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(karpatkeyToken.InsufficientTransferAllowance.selector, _holder, address(0), 0, _amount)
    );
    _kpktoken.burn(_amount);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_holder, address(0), _amount - 1);
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(
        karpatkeyToken.InsufficientTransferAllowance.selector, _holder, address(0), _amount - 1, _amount
      )
    );
    _kpktoken.burn(_amount);
  }

  function testBurnWhenUnpaused() public {
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), _amountToMint - _amount + 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnWhenUnpausedExpectedRevertERC20InsufficientBalance() public {
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, _holder, _amountToMint, _amountToMint + 1)
    );
    _kpktoken.burn(_amountToMint + 1);
  }
}
