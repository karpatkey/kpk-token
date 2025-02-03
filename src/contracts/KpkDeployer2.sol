// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
//import {TimelockController} from 'contracts/TimelockController.sol'; In case we wanna use an upgradeable version
import {
  BATCH_PLANNER,
  CLIFF_IN_SECONDS,
  GNOSIS_DAO_TREASURY_SAFE,
  IBatchPlanner,
  KARPATKEY_TREASURY_SAFE,
  SECONDS_IN_A_YEAR,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS
} from './kpkDeployerLib.sol';

contract KpkDeployer {
  address public kpkTokenAddress;

  IBatchPlanner.AllocationData[] public allocations;
  IBatchPlanner.Plan[] public plans;

  uint256 public MIN_DELAY = 60;
  address[] public PROPOSERS;
  address[] public EXECUTORS;

  constructor() {
    /*The Proposer role is in charge of queueing operations: this is the role the Governor instance should be
    granted, and it should likely be the only proposer in the system.

    The Executor role is in charge of executing already available operations: we can assign this role to the
    special zero address to allow anyone to execute (if operations can be particularly time sensitive, the
    Governor should be made Executor instead).

    Lastly, there is the Admin role, which can grant and revoke the two previous roles: this is a very sensitive
    role that will be granted automatically to the timelock itself, and optionally to a second account, which can
    be used for ease of setup but should promptly renounce the role.

    See https://docs.openzeppelin.com/contracts/5.x/governance#timelock
    */
    EXECUTORS.push(address(0));
    // The Governor contract instance shall be later granted the Proposer role, that's why the KpkDeployer is
    //temporarily set as an admin of of the TimelockController
    // Should we assign an alternative admin (instead of address(0))? The Foundation safe?

    TimelockController timelockController = new TimelockController(MIN_DELAY, PROPOSERS, EXECUTORS, address(this));

    // Do we want this one to be upgradeable? The following code would accomplish that. What's the proxy admin then?

    /* TimelockController timelockControllerImpl = new TimelockController();
    address timelockControllerProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(timelockControllerImpl),
        TIMELOCK_CONTROLLER_PROXY_ADMIN,
        abi.encodeWithSignature(
          'initialize(uint256,address[],address[],address)',
          MIN_DELAY,
          PROPOSERS,
          EXECUTORS,
          address(0) // Do we want an optional admin?
        )
      )
    ); */

    KpkToken kpkTokenImpl = new KpkToken();
    address kpkTokenProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkTokenImpl), // Implementation
        address(timelockController), // Proxy admin
        abi.encodeWithSignature('initialize(address)', address(this)) // The owner temporarily is the KpkDeployer itself
      )
    );
    KpkToken kpkToken = KpkToken(kpkTokenProxyAddress);
    kpkTokenAddress = address(kpkToken);

    KpkGovernor kpkGovernorImpl = new KpkGovernor();
    address kpkGovernorProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkGovernorImpl), // Implementation
        address(timelockController), // Proxy admin
        abi.encodeWithSignature('initialize(address,address)', address(kpkToken), address(timelockController))
      )
    );
    KpkGovernor kpkGovernor = KpkGovernor(payable(kpkGovernorProxyAddress));

    timelockController.grantRole(timelockController.PROPOSER_ROLE(), address(kpkGovernor));
    timelockController.renounceRole(timelockController.DEFAULT_ADMIN_ROLE(), address(this));

    uint256 totalAllocation = 0;

    allocations.push(IBatchPlanner.AllocationData(GNOSIS_DAO_TREASURY_SAFE, 25_000_000 ether, 1_642_075_200, false));
    allocations.push(
      IBatchPlanner.AllocationData(
        GNOSIS_DAO_TREASURY_SAFE, 75_000_000 ether, block.timestamp + SECONDS_IN_A_YEAR, false
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
      TOKEN_VESTING_PLANS, address(kpkToken), totalAllocation, plans, 1, KARPATKEY_TREASURY_SAFE, true, 4
    ); // Should the admin be the Foundation safe? I believe so...

    // Transfer the remaining tokens to the karpatkey Treasury Safe
    kpkToken.transfer(KARPATKEY_TREASURY_SAFE, kpkToken.balanceOf(address(this)));
    kpkToken.transferAllowlist(KARPATKEY_TREASURY_SAFE, true);
    kpkToken.transferOwnership(address(timelockController)); // Is this correct?
  }
}
