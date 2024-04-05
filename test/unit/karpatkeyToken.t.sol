// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {Test} from 'forge-std/Test.sol';
import {Upgrades} from 'openzeppelin-foundry-upgrades/Upgrades.sol';

abstract contract Base is Test {
  address internal _owner = makeAddr('owner');
  karpatkeyToken internal _kpktoken;
  address internal _proxy;

  function setUp() public virtual {
    _proxy =
      Upgrades.deployTransparentProxy('karpatkeyToken.sol', _owner, abi.encodeCall(karpatkeyToken.initialize, _owner));
    _kpktoken = karpatkeyToken(_proxy);
  }
}

contract UnitTestConstructor is Base {
  function test_Constructor() public view {
    assertEq(_kpktoken.owner(), _owner);
    assertEq(_kpktoken.totalSupply(), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.balanceOf(_owner), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.name(), 'karpatkey Token');
    assertEq(_kpktoken.symbol(), 'KPK');
    assertEq(_kpktoken.decimals(), 18);
    assertEq(_kpktoken.paused(), true);
  }
}

contract UnitTestPause is Base {
  function test_UnpauseExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.unpause();
  }

  function test_Unpause() public {
    vm.prank(_owner);
    _kpktoken.unpause();
    assertEq(_kpktoken.paused(), false);
  }
}

contract UnitTestTransferOwnership is Base {
  function test_transferOwnership() public {
    address _newOwner = makeAddr('newOwner');
    vm.prank(_owner);
    _kpktoken.transferOwnership(_newOwner);
    assertEq(_kpktoken.owner(), _newOwner);
  }

  function test_transferOwnershipExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _newOwner = makeAddr('newOwner');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferOwnership(_newOwner);
  }
}

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
    _kpktoken.transferAllowlist(_holder);
    uint256 _initialTotalSupply = _kpktoken.totalSupply();
    vm.startPrank(_holder);
    _kpktoken.burn(_amount - 1);
    assertEq(_kpktoken.balanceOf(_holder), 1);
    assertEq(_kpktoken.totalSupply(), _initialTotalSupply - _amount + 1);
  }

  function test_BurnExpectedRevert() public {
    address _holder = makeAddr('holder');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    _kpktoken.mint(_holder, _amount);
    _kpktoken.transferAllowlist(_holder);
    vm.startPrank(_holder);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, _holder, _amount, _amount + 1)
    );
    _kpktoken.burn(_amount + 1);
  }
}

contract UnitTestMint is Base {
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

contract UnitTestTransferAllowlisting is Base {
  function test_transferAllowlist() public {
    address _sender = makeAddr('sender');
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowlisted(_sender), false);
    _kpktoken.transferAllowlist(_sender);
    assertEq(_kpktoken.transferAllowlisted(_sender), true);
  }

  function test_transferAllowlistExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.transferAllowlist(_randomAddress);
  }

  function test_transferAllowlistWhenUnpausedExpectedRevert() public {
    address _sender = makeAddr('sender');
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferAllowlistingWhenUnpaused.selector));
    _kpktoken.transferAllowlist(_sender);
  }
}

contract UnitTestTransferAllowance is Base {
  event TransferApproval(address indexed _sender, address indexed _recipient, uint256 _value);

  function test_transferAllowance() public {
    address _sender = makeAddr('sender');
    address _recipient = makeAddr('recipient');

    uint256 _amount = 100;
    vm.startPrank(_owner);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 0);
    vm.expectEmit(address(_kpktoken));
    emit TransferApproval(_sender, _recipient, _amount);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), _amount);
  }

  function test_transferAllowanceExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    address _recipient = makeAddr('recipient');
    uint256 _amount = 100;
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.approveTransfer(_randomAddress, _recipient, _amount);
  }

  function test_transferAllowanceWhenPausedExpectedRevert() public {
    uint256 _amount = 100;
    address _sender = makeAddr('sender');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.unpause();
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferApprovalWhenUnpaused.selector));
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
  }

  function test_transferAllowanceAllowlistedExpectedRevert() public {
    uint256 _amount = 100;
    address _sender = makeAddr('sender');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.transferAllowlist(_sender);
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.OwnerAlreadyAllowlisted.selector, _sender));
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
  }
}

contract UnitTestFirstTransfer is Base {
  function test_firstTransfer() public {
    address _recipient = makeAddr('recipient');
    uint256 _amount = 100;
    vm.startPrank(_owner);
    bool _result = _kpktoken.transfer(_recipient, _amount);
    assertEq(_result, true);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_owner), _kpktoken.totalSupply() - _amount);
  }
}

abstract contract BaseTransfer is Base {
  address internal _sender = makeAddr('sender');
  address internal _recipient = makeAddr('recipient');
  uint256 internal _amount = 100;

  function setUp() public virtual override(Base) {
    super.setUp();
    vm.startPrank(_owner);
    _kpktoken.transfer(_sender, _amount);
  }
}

contract UnitTestTransfers is BaseTransfer {
  function test_transferExpectedRevert() public {
    vm.startPrank(_sender);
    vm.expectRevert(
      abi.encodeWithSelector(karpatkeyToken.InsufficientTransferAllowance.selector, _sender, _recipient, 0, _amount)
    );
    _kpktoken.transfer(_recipient, _amount);
  }

  function test_transfer() public {
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount + 1);
    vm.startPrank(_sender);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_sender), 0);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 1);
  }

  function test_transferInfiniteTransferAllowance() public {
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, type(uint256).max);
    vm.startPrank(_sender);
    _kpktoken.transfer(_recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
    assertEq(_kpktoken.balanceOf(_sender), 0);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), type(uint256).max);
  }

  function test_transferToContractExpectedRevert() public {
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount + 1);
    vm.startPrank(_sender);
    vm.expectRevert(abi.encodeWithSelector(karpatkeyToken.TransferToTokenContract.selector));
    _kpktoken.transfer(address(_kpktoken), _amount);
  }
}

contract UnitTestTransferFrom is BaseTransfer {
  function test_transferFrom() public {
    address _mover = makeAddr('mover');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_sender);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_owner);
    _kpktoken.approveTransfer(_sender, _recipient, _amount);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_sender, _recipient, _amount - 1);
    assertEq(_kpktoken.balanceOf(_recipient), _amount - 1);
    assertEq(_kpktoken.balanceOf(_sender), 1);
    assertEq(_kpktoken.transferAllowance(_sender, _recipient), 1);
  }

  function test_transferFromExpectedRevert() public {
    address _mover = makeAddr('mover');
    address _recipient = makeAddr('recipient');
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

  function test_transferFromOwner() public {
    address _mover = makeAddr('mover');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    _kpktoken.transferFrom(_owner, _recipient, _amount);
    assertEq(_kpktoken.balanceOf(_recipient), _amount);
  }

  function test_transferFromOwnerExpectedRevert() public {
    address _mover = makeAddr('mover');
    address _recipient = makeAddr('recipient');
    vm.startPrank(_owner);
    _kpktoken.approve(_mover, _amount);
    vm.startPrank(_mover);
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _mover, _amount, _amount + 1)
    );
    _kpktoken.transferFrom(_owner, _recipient, _amount + 1);
  }
}

abstract contract BaseRescueToken is Base {
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
}

contract UnitTestRescueToken is BaseRescueToken {
  function test_rescueToken() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    _kpktoken.rescueToken(_dai, _beneficiary, _amount - 1);
    assertEq(_dai.balanceOf(_beneficiary), _amount - 1);
    assertEq(_dai.balanceOf(address(_kpktoken)), 1);
  }

  function test_rescueTokenExpectedRevert() public {
    address _beneficiary = makeAddr('beneficiary');
    vm.startPrank(_owner);
    vm.expectRevert(
      abi.encodeWithSelector(karpatkeyToken.InsufficientBalanceToRescue.selector, _dai, _amount + 1, _amount)
    );
    _kpktoken.rescueToken(_dai, _beneficiary, _amount + 1);
  }

  function test_rescueTokenExpectedRevertOwner() public {
    address _randomAddress = makeAddr('randomAddress');
    vm.startPrank(_randomAddress);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _randomAddress));
    _kpktoken.rescueToken(_dai, _randomAddress, _amount);
  }
}
