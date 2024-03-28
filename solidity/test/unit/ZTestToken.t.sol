// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';
import 'forge-std/console.sol';

import {IZTT} from 'interfaces/IZTT.sol';
import {ZTestToken} from 'solidity/contracts/ZTestToken.sol';

abstract contract Base is Test {
  address internal _owner = makeAddr('owner');
  ZTestToken internal _ztoken;

  function setUp() public virtual {
    _ztoken = new ZTestToken(_owner);
  }
}

contract TestConstructor is Base {
  function test_Constructor() public {
    assertEq(_ztoken.owner(), _owner);
    assertEq(_ztoken.transferAllowance(_owner), type(uint256).max);
    assertEq(_ztoken.totalSupply(), 1_000_000e18);
    assertEq(_ztoken.balanceOf(_owner), 1_000_000e18);
    assertEq(_ztoken.name(), 'ZTest Token');
    assertEq(_ztoken.symbol(), 'ZTT');
    assertEq(_ztoken.decimals(), 18);
    assertEq(_ztoken.paused(), true);
  }
}

contract TestPause is Base {
  function test_UnpauseExpectedRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496)
    );
    _ztoken.unpause();
  }

  function test_Pause() public {
    vm.prank(_owner);
    _ztoken.unpause();
    assertEq(_ztoken.paused(), false);
  }
}

contract TestTransferOwnership is Base {
  function test_transferOwnership() public {
    address _newOwner = makeAddr('newOwner');

    vm.prank(_owner);
    _ztoken.transferOwnership(_newOwner);
    assertEq(_ztoken.owner(), _newOwner);
    assertEq(_ztoken.transferAllowance(_newOwner), type(uint256).max);
    assertEq(_ztoken.transferAllowance(_owner), 0);
  }
}
