// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';

import {Base} from '.././Base.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestBurnFrom is Base {
  address internal _sender = makeAddr('sender');
  address internal _mover = makeAddr('mover');
  uint256 internal _amount = 100;
  uint256 internal _initialTotalSupply;
  uint256 internal _initialOwnerBalance;

  function setUp() public virtual override(Base) {
    super.setUp();
    _initialTotalSupply = _kpktoken.totalSupply();
    vm.startPrank(_owner);
    _kpktoken.transfer(_sender, _amount);
    _initialOwnerBalance = _kpktoken.balanceOf(_owner);
  }

  function testBurnFromOwner() public {
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    _kpktoken.burnFrom(_owner, _amount - 1);
    assertEq(_kpktoken.balanceOf(_owner), _initialOwnerBalance - _amount + 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnFromOwnerExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount, _amount + 1)
    );
    _kpktoken.burnFrom(_owner, _amount + 1);
  }

  function testBurnFromTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, address(0), _amount);
    vm.startPrank(_mover);
    _kpktoken.burnFrom(_sender, _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.transferAllowance(_sender, address(0)), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnFromInfiniteTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, address(0), type(uint256).max);
    vm.startPrank(_mover);
    _kpktoken.burnFrom(_sender, _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.transferAllowance(_sender, address(0)), type(uint256).max);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnFromExpectedRevertInsufficientTransferAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount + 1);
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, address(0), _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(
        karpatkeyToken.InsufficientTransferAllowance.selector, _sender, address(0), _amount, _amount + 1
      )
    );
    _kpktoken.burnFrom(_sender, _amount + 1);
  }

  function testBurnFromExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.increaseTransferAllowance(_sender, address(0), _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.transferFrom(_sender, address(0), _amount);
  }

  function testBurnFromTransferAllowlist() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_sender, true);
    vm.startPrank(_mover);
    _kpktoken.burnFrom(_sender, _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnFromTransferAllowlistExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_sender, true);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.burnFrom(_sender, _amount);
  }

  function testBurnFromWhenUnpaused() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_mover);
    _kpktoken.burnFrom(_sender, _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.allowance(_sender, _mover), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function testBurnFromWhenUnpausedExpectedRevertERC20InsufficientAllowance() public {
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount - 1);
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount - 1, _amount)
    );
    _kpktoken.burnFrom(_sender, _amount);
  }
}
