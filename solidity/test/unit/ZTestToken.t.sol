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
    assertEq(_ztoken.totalSupply(), 1_000_000 * 10 ** _ztoken.decimals());
    assertEq(_ztoken.balanceOf(_owner), 1_000_000 * 10 ** _ztoken.decimals());
    assertEq(_ztoken.name(), 'ZTest Token');
    assertEq(_ztoken.symbol(), 'ZTT');
    assertEq(_ztoken.decimals(), 18);
    assertEq(_ztoken.paused(), true);
  }
}

contract TestPause is Base {
  function test_UnpauseExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.unpause();
  }

  function test_Pause() public {
    vm.prank(_owner);
    _ztoken.unpause();
    assertEq(_ztoken.paused(), false);
  }

  function test_PauseExpectedRevertOwner() public {
    vm.prank(_owner);
    _ztoken.unpause();
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.pause();
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

  function test_transferOwnershipExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _newOwner = makeAddr('newOwner');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.transferOwnership(_newOwner);
  }
}

contract TestTransferAllowance is Base {
  function test_transferAllowance() public {
    address _holder = makeAddr('holder');
    uint256 amount = 100;
    vm.startPrank(_owner);
    assertEq(_ztoken.transferAllowance(_holder), 0);
    //vm.expectEmit(address(_ztoken));
    //emit IZTT.TransferApproval(_holder, amount);
    _ztoken.approveTransfer(_holder, amount);
    assertEq(_ztoken.transferAllowance(_holder), amount);
  }

  function test_transferAllowanceExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    uint256 amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.approveTransfer(_randomAddress, amount);
  }
}

contract TestTransfer is Base {
  function test_firstTransfer() public {
    address _recipient = makeAddr('recipient');
    uint256 amount = 100;
    vm.startPrank(_owner);
    _ztoken.transfer(_recipient, amount);
    assertEq(_ztoken.balanceOf(_recipient), amount);
    assertEq(_ztoken.balanceOf(_owner), _ztoken.totalSupply() - amount);
  }
}

abstract contract BaseTransfer is Base {
  address internal _holder = makeAddr('holder');
  uint256 internal amount = 100;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _ztoken.transfer(_holder, amount);
  }
}

contract TestTransfers is BaseTransfer {
  function test_transferExpectedRevert() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_holder);
    vm.expectRevert(abi.encodeWithSelector(IZTT.InsufficientTransferAllowance.selector, _holder, 0, amount));
    _ztoken.transfer(_recipient, amount);
  }

  function test_transfer() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _ztoken.approveTransfer(_holder, amount + 1);
    vm.startPrank(_holder);
    _ztoken.transfer(_recipient, amount);
    assertEq(_ztoken.balanceOf(_recipient), amount);
    assertEq(_ztoken.balanceOf(_holder), 0);
    assertEq(_ztoken.transferAllowance(_holder), 1);
  }

  function test_transferInfiniteTransferAllowance() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _ztoken.approveTransfer(_holder, type(uint256).max);
    vm.startPrank(_holder);
    _ztoken.transfer(_recipient, amount);
    assertEq(_ztoken.balanceOf(_recipient), amount);
    assertEq(_ztoken.balanceOf(_holder), 0);
    assertEq(_ztoken.transferAllowance(_holder), type(uint256).max);
  }

  function test_transferByOwner() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _ztoken.transferByOwner(_holder, _recipient, amount - 1);
    assertEq(_ztoken.balanceOf(_recipient), amount - 1);
    assertEq(_ztoken.balanceOf(_holder), 1);
  }

  function test_transferByOwnerExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.transferByOwner(_holder, _recipient, amount - 1);
  }
}

abstract contract BaseRescueToken is Base {
  uint256 internal constant _FORK_BLOCK = 19_534_932;
  address internal _daiWhale = 0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
  IERC20 internal _dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  uint256 internal amount = 100;

  function setUp() public virtual override(Base) {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);
    super.setUp();
    vm.prank(_daiWhale);
    _dai.transfer(address(_ztoken), amount);
  }
}

contract TestRescueToken is BaseRescueToken {
  function test_rescueToken() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    _ztoken.rescueToken(_dai, _beneficiary, amount - 1);
    assertEq(_dai.balanceOf(_beneficiary), amount - 1);
    assertEq(_dai.balanceOf(address(_ztoken)), 1);
  }

  function test_rescueTokenExpectedRevert() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    vm.expectRevert(abi.encodeWithSelector(IZTT.NotEnoughBalanceToRescue.selector, _dai, amount + 1));
    _ztoken.rescueToken(_dai, _beneficiary, amount + 1);
  }

  function test_rescueTokenExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _ztoken.rescueToken(_dai, _randomAddress, amount);
  }
}
