// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';

contract UnitTestRescueToken is Base {
  uint256 internal constant _FORK_BLOCK = 19_534_932;
  address internal _daiWhale = 0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
  IERC20 internal _dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  uint256 internal _amount = 100;

  function setUp() public virtual override(Base) {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);
    super.setUp();
    vm.prank(_daiWhale);
    _dai.transfer(address(_kpktoken), _amount);
  }

  function testRescueToken() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    _kpktoken.rescueToken(_dai, _beneficiary, _amount - 1);
    assertEq(_dai.balanceOf(_beneficiary), _amount - 1);
    assertEq(_dai.balanceOf(address(_kpktoken)), 1);
  }

  function testRescueTokenExpectedRevertInsufficientBalanceToRescue() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    vm.expectRevert(
      abi.encodeWithSelector(karpatkeyToken.InsufficientBalanceToRescue.selector, _dai, _amount + 1, _amount)
    );
    _kpktoken.rescueToken(_dai, _beneficiary, _amount + 1);
  }

  function testRescueTokenExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.rescueToken(_dai, _randomAddress, _amount);
  }
}
