// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

import {KpkTokenDeploymentConfig} from 'contracts/KpkTokenDeploymentConfig.sol';
import {TimelockController} from 'contracts/TimelockController.sol';
import {
  BATCH_PLANNER,
  CLIFF_IN_SECONDS,
  IBatchPlanner,
  SAFE_PROXY_FACTORY,
  SECONDS_IN_TWO_YEARS
} from 'contracts/kpkDeployerLib.sol';

interface ISafeProxyFactory {
  function createProxyWithNonce(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce
  ) external returns (address proxy);
}

contract KpkDeployer {
  address public TOKEN_VESTING_PLANS = 0x68b6986416c7A38F630cBc644a2833A0b78b3631;
  address public KARPATKEY_TREASURY_SAFE = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC; //Dummy deployer

  IBatchPlanner.AllocationData[] public allocations;
  IBatchPlanner.Plan[] public plans;

  uint256 public MIN_DELAY = 60;
  address[] public PROPOSERS;
  address[] public EXECUTORS;
  address public TIMELOCK_CONTROLLER_ADMIN;

  constructor() {
    ISafeProxyFactory safeProxyFactory;
    safeProxyFactory = ISafeProxyFactory(SAFE_PROXY_FACTORY);
    address karpatkeyGovernanceSafe = address(
      safeProxyFactory.createProxyWithNonce(
        0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
        abi.encodeWithSignature(
          'setup(address[],uint256,address,bytes,address,address,uint256,address)',
          KpkTokenDeploymentConfig.governanceSafeOwners(),
          KpkTokenDeploymentConfig.governanceSafeThreshold(),
          address(0),
          bytes('0x'),
          0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
          address(0),
          0,
          address(0)
        ),
        block.timestamp
      )
    );

    KpkToken kpkTokenImpl = new KpkToken();
    address kpkTokenProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkTokenImpl), karpatkeyGovernanceSafe, abi.encodeWithSignature('initialize(address)', address(this))
      )
    );

    KpkToken kpkToken = KpkToken(kpkTokenProxyAddress);

    PROPOSERS.push(karpatkeyGovernanceSafe);
    EXECUTORS.push(karpatkeyGovernanceSafe);
    TIMELOCK_CONTROLLER_ADMIN = karpatkeyGovernanceSafe;

    TimelockController timelockControllerImpl = new TimelockController();
    address timelockControllerProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(timelockControllerImpl),
        TIMELOCK_CONTROLLER_ADMIN,
        abi.encodeWithSignature(
          'initialize(uint256,address[],address[],address)', MIN_DELAY, PROPOSERS, EXECUTORS, TIMELOCK_CONTROLLER_ADMIN
        )
      )
    );

    TimelockController timelockController = TimelockController(payable(timelockControllerProxyAddress));

    KpkGovernor kpkGovernorImpl = new KpkGovernor();
    address kpkGovernorProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkGovernorImpl),
        karpatkeyGovernanceSafe,
        abi.encodeWithSignature('initialize(address,address)', address(kpkToken), address(timelockController))
      )
    );

    KpkGovernor kpkGovernor = KpkGovernor(payable(kpkGovernorProxyAddress));

    uint256 totalAllocation = 0;

    allocations.push(
      IBatchPlanner.AllocationData(
        0x80e26ecEA683a9d4a5d511c084e1B050C72f15a9, 1000 ether, block.timestamp - 30 * 24 * 3600, false
      )
    );

    for (uint256 i = 0; i < allocations.length; i++) {
      totalAllocation += allocations[i].amount;
      plans.push(
        IBatchPlanner.Plan(
          allocations[i].recipient,
          allocations[i].amount,
          allocations[i].start,
          allocations[i].cliffBool ? allocations[i].start + CLIFF_IN_SECONDS : allocations[i].start,
          allocations[i].amount / SECONDS_IN_TWO_YEARS
        )
      );
    }
    kpkToken.transferAllowlist(TOKEN_VESTING_PLANS, true);
    kpkToken.transferAllowlist(BATCH_PLANNER, true);

    kpkToken.approve(BATCH_PLANNER, totalAllocation);

    IBatchPlanner(BATCH_PLANNER).batchVestingPlans(
      TOKEN_VESTING_PLANS, address(kpkToken), totalAllocation, plans, 1, karpatkeyGovernanceSafe, true, 4
    );

    // Transfer the remaining tokens to the karpatkey Treasury Safe
    kpkToken.transfer(KARPATKEY_TREASURY_SAFE, kpkToken.balanceOf(address(this)));
    kpkToken.transferAllowlist(KARPATKEY_TREASURY_SAFE, true);
    kpkToken.transferOwnership(karpatkeyGovernanceSafe);
  }

  function getNumberOfGovernanceSafeOwners() public view returns (uint256) {
    return KpkTokenDeploymentConfig.governanceSafeOwners().length;
  }
}
