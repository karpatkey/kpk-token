// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';
import 'forge-std/console.sol';

import {IkarpatkeyToken} from 'interfaces/IkarpatkeyToken.sol';
import {karpatkeyToken} from 'solidity/contracts/karpatkeyToken.sol';

abstract contract Base is Test {
  address internal _owner = makeAddr('owner');
  karpatkeyToken internal _kpktoken;

  function setUp() public virtual {
    _kpktoken = new karpatkeyToken(_owner);
  }
}

contract TestConstructor is Base {
  function test_Constructor() public {
    assertEq(_kpktoken.owner(), _owner);
    assertEq(_kpktoken.transferAllowance(_owner), type(uint256).max);
    assertEq(_kpktoken.totalSupply(), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.balanceOf(_owner), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.name(), 'karpatkey Token');
    assertEq(_kpktoken.symbol(), 'KPK');
    assertEq(_kpktoken.decimals(), 18);
    assertEq(_kpktoken.paused(), true);
  }
}

contract TestPause is Base {
  function test_UnpauseExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.unpause();
  }

  function test_Pause() public {
    vm.prank(_owner);
    _kpktoken.unpause();
    assertEq(_kpktoken.paused(), false);
  }

  function test_PauseExpectedRevertOwner() public {
    vm.prank(_owner);
    _kpktoken.unpause();
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.pause();
  }
}

contract TestTransferOwnership is Base {
  function test_transferOwnership() public {
    address _newOwner = makeAddr('newOwner');
    vm.prank(_owner);
    _kpktoken.transferOwnership(_newOwner);
    assertEq(_kpktoken.owner(), _newOwner);
    assertEq(_kpktoken.transferAllowance(_newOwner), type(uint256).max);
    assertEq(_kpktoken.transferAllowance(_owner), 0);
  }

  function test_transferOwnershipExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _newOwner = makeAddr('newOwner');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferOwnership(_newOwner);
  }
}

contract TestBurn is Base {
  function test_Burn() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    _kpktoken.burn(_holder, _amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function test_BurnExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.prank(_owner);
    _kpktoken.mint(_holder, _amount);
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.burn(_holder, _amount - 1);
  }

  function test_BurnExpectedRevert() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, _holder, _amount, _amount + 1)
    );
    _kpktoken.burn(_holder, _amount + 1);
  }
}

contract TestMint is Base {
  function test_Mint() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.prank(_owner);
    _kpktoken.mint(_holder, _amount);
    assertEq(_kpktoken.balanceOf(_holder), _amount);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply + _amount);
  }

  function test_MintExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.mint(_holder, _amount);
  }
}

contract TestTransferAllowance is Base {
  function test_transferAllowance() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowance(_holder), 0);
    // FIXME: This is not working
    // vm.expectEmit(address(_kpktoken));
    // emit IkarpatkeyToken.TransferApproval(_holder, _amount);
    _kpktoken.approveTransfer(_holder, _amount);
    assertEq(_kpktoken.transferAllowance(_holder), _amount);
  }

  function test_transferAllowanceExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    uint256 _amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.approveTransfer(_randomAddress, _amount);
  }

  function test_transferAllowanceWhenPausedExpectedRevert() public {
    uint256 _amount = 100;
    address _holder = makeAddr('holder');
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(IkarpatkeyToken.TransferApprovalWhenUnpaused.selector));
    _kpktoken.approveTransfer(_holder, _amount);
  }
}

contract TestFirstTransfer is Base {
  function test_firstTransfer() public {
    address _recipient = makeAddr('recipient');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    bool result = _kpktoken.transfer(_recipient, _amount);
    assertEq(result, true);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_owner), _kpktoken.totalSupply() - _amount);
  }
}

abstract contract BaseTransfer is Base {
  address internal _holder = makeAddr('holder');
  uint256 internal _amount = 100;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.transfer(_holder, _amount);
  }
}

contract TestTransfers is BaseTransfer {
  function test_transferExpectedRevert() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_holder);
    vm.expectRevert(abi.encodeWithSelector(IkarpatkeyToken.InsufficientTransferAllowance.selector, _holder, 0, _amount));
    _kpktoken.transfer(_recipient, _amount);
  }

  function test_transfer() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_holder, _amount + 1);
    vm.startPrank(_holder);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_holder), 0);
    assertEq(_kpktoken.transferAllowance(_holder), 1);
  }

  function test_transferInfiniteTransferAllowance() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_holder, type(uint256).max);
    vm.startPrank(_holder);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_holder), 0);
    assertEq(_kpktoken.transferAllowance(_holder), type(uint256).max);
  }

  function test_transferToContractExpectedRevert() public {
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_holder, _amount + 1);
    vm.startPrank(_holder);
    vm.expectRevert(abi.encodeWithSelector(IkarpatkeyToken.TransferToTokenContract.selector));
    _kpktoken.transfer(address(_kpktoken), _amount);
  }

  function test_transferByOwner() public {
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    bool _result = _kpktoken.transferByOwner(_holder, _recipient, _amount - 1);
    assertEq(_result, true);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), 1);
  }

  function test_transferByOwnerExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferByOwner(_holder, _recipient, _amount - 1);
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
    _dai.transfer(address(_kpktoken), amount);
  }
}

contract TestRescueToken is BaseRescueToken {
  function test_rescueToken() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    _kpktoken.rescueToken(_dai, _beneficiary, amount - 1);
    assertEq(_dai.balanceOf(_beneficiary), amount - 1);
    assertEq(_dai.balanceOf(address(_kpktoken)), 1);
  }

  function test_rescueTokenExpectedRevert() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    vm.expectRevert(
      abi.encodeWithSelector(IkarpatkeyToken.InsufficientBalanceToRescue.selector, _dai, amount + 1, amount)
    );
    _kpktoken.rescueToken(_dai, _beneficiary, amount + 1);
  }

  function test_rescueTokenExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.rescueToken(_dai, _randomAddress, amount);
  }
}