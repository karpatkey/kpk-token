// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {KpkTokenDeploymentConfig} from './KpkTokenDeploymentConfig.sol';
import {
  BATCH_PLANNER as BATCH_PLANNER_1,
  CLIFF_IN_SECONDS,
  GNOSIS_DAO_TREASURY_SAFE,
  IBatchPlanner,
  ISafeProxyFactory,
  KARPATKEY_TREASURY_SAFE as KARPATKEY_TREASURY_SAFE_1,
  SAFE_PROXY_FACTORY,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS as TOKEN_VESTING_PLANS_1
} from './kpkDeployerLib.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

contract KpkDeployer {
  address public KARPATKEY_TREASURY_SAFE = KARPATKEY_TREASURY_SAFE_1;
  /// @notice Address of the BatchPlanner contract
  address public BATCH_PLANNER = BATCH_PLANNER_1;
  /// @notice Address of the TokenVestingPlans contract
  address public TOKEN_VESTING_PLANS = TOKEN_VESTING_PLANS_1;

  IBatchPlanner.AllocationData[] public allocations;
  IBatchPlanner.Plan[] public plans;

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

    KpkToken impl = new KpkToken();
    KpkToken kpkToken = KpkToken(
      address(
        new TransparentUpgradeableProxy(
          address(impl),
          karpatkeyGovernanceSafe,
          abi.encodeWithSignature('initialize(address)', address(this)) // initialize the token
        )
      )
    );

    allocations = KpkTokenDeploymentConfig.getTokenAllocations(block.timestamp);

    uint256 totalAllocation = 0;

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
