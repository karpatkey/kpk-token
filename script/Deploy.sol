// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {Upgrades} from '@openzeppelin/foundry-upgrades/src/Upgrades.sol';
import {
  BATCH_PLANNER,
  BATCH_PLANNER_SEPOLIA,
  GNOSIS_DAO_TREASURY_SAFE,
  IBatchPlanner,
  KARPATKEY_TREASURY_SAFE,
  SECONDS_IN_A_YEAR,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS,
  TOKEN_VESTING_PLANS_SEPOLIA
} from 'contracts/KpkDeployerLib.sol';

import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';

abstract contract DeployToken is Script {
  KpkToken kpkToken;
  TimelockController timelockController;

  IBatchPlanner.Plan[] plans;
  address tokenVestingPlansAddress;
  address batchPlannerAddress;

  uint256 MIN_DELAY = 120;
  address[] PROPOSERS;
  address[] EXECUTORS;

  function _deploy(
    address _deployerAddress,
    address _vestingPlansRecipientAddress,
    address _finalHolderOfKpkAddress,
    bool deployOnSepolia
  ) internal {
    EXECUTORS.push(address(0));

    vm.startBroadcast();

    timelockController = new TimelockController(MIN_DELAY, PROPOSERS, EXECUTORS, _deployerAddress);

    address kpktokenProxyAddress = Upgrades.deployTransparentProxy(
      'KpkToken.sol', address(timelockController), abi.encodeCall(KpkToken.initialize, _deployerAddress)
    );
    kpkToken = KpkToken(kpktokenProxyAddress);

    address kpkGovernorProxyAddress = Upgrades.deployTransparentProxy(
      'KpkGovernor.sol',
      address(timelockController),
      abi.encodeWithSignature('initialize(address,address)', address(kpkToken), address(timelockController))
    );

    timelockController.grantRole(timelockController.PROPOSER_ROLE(), kpkGovernorProxyAddress);
    timelockController.renounceRole(timelockController.DEFAULT_ADMIN_ROLE(), _deployerAddress);

    plans.push(
      IBatchPlanner.Plan(
        _vestingPlansRecipientAddress,
        25_000_000 ether,
        1_642_075_200,
        1_642_075_200,
        (25_000_000 ether) / SECONDS_IN_TWO_YEARS
      )
    );

    plans.push(
      IBatchPlanner.Plan(
        _vestingPlansRecipientAddress,
        75_000_000 ether,
        block.timestamp + SECONDS_IN_A_YEAR,
        block.timestamp + SECONDS_IN_A_YEAR,
        (75_000_000 ether) / SECONDS_IN_TWO_YEARS
      )
    );

    tokenVestingPlansAddress = deployOnSepolia ? TOKEN_VESTING_PLANS_SEPOLIA : TOKEN_VESTING_PLANS;
    batchPlannerAddress = deployOnSepolia ? BATCH_PLANNER_SEPOLIA : BATCH_PLANNER;

    kpkToken.transferAllowlist(tokenVestingPlansAddress, true);
    kpkToken.transferAllowlist(batchPlannerAddress, true);

    kpkToken.approve(batchPlannerAddress, 25_000_000 ether + 75_000_000 ether);

    IBatchPlanner(batchPlannerAddress).batchVestingPlans(
      tokenVestingPlansAddress,
      address(kpkToken),
      25_000_000 ether + 75_000_000 ether,
      plans,
      1,
      _finalHolderOfKpkAddress,
      true,
      4
    );

    // Transfer the remaining tokens to the karpatkey Treasury Safe
    kpkToken.transfer(_finalHolderOfKpkAddress, kpkToken.balanceOf(_deployerAddress));
    kpkToken.transferAllowlist(_finalHolderOfKpkAddress, true);
    kpkToken.transferOwnership(address(timelockController));

    vm.stopBroadcast();
  }
}

contract DeployTokenSepolia is DeployToken {
  function run() external {
    address _deployerAddress = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC;
    address _vestingPlansRecipientAddress = 0x80e26ecEA683a9d4a5d511c084e1B050C72f15a9;
    address _finalHolderOfKpkAddress = 0x495f9Cd38351A199ac6ff3bB952D0a65DD464736;
    _deploy(_deployerAddress, _vestingPlansRecipientAddress, _finalHolderOfKpkAddress, true);
  }
}
