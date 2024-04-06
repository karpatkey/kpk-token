// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestBurn is Base {
  function test_BurnOwner() public {
    uint256 _amount = 100;
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.startPrank(_owner);
    _kpktoken.burn(_amount);
    assertEq(_kpktoken.balanceOf(_owner), _initialTotalSupply - _amount);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount);
  }

  function test_BurnAllowlisted() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    _kpktoken.transferAllowlist(_holder, true);
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function test_BurnTransferAllowance() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    _kpktoken.approveTransfer(_holder, address(0), _amount);
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), 1);
    assertEq(_kpktoken.transferAllowance(_holder, address(0)), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function test_BurnExpectedRevertERC20InsufficientBalance() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    _kpktoken.transferAllowlist(_holder, true);
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, _holder, _amount, _amount + 1)
    );
    _kpktoken.burn(_amount + 1);
  }

  function test_BurnExpectedRevertInsufficientTransferAllowance() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
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
}
