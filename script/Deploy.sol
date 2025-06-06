// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {Upgrades} from '@openzeppelin/foundry-upgrades/src/Upgrades.sol';
import {
  BATCH_PLANNER,
  BATCH_PLANNER_SEPOLIA,
  GNOSIS_DAO_TREASURY_SAFE,
  IBatchPlanner,
  KPK_TREASURY_SAFE,
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
  KpkToken public kpkToken;
  TimelockController public timelockController;
  KpkGovernor public kpkGovernor;

  IBatchPlanner.Plan[] plans;
  address public tokenVestingPlansAddress;
  address batchPlannerAddress;

  uint256 public GNOSIS_DAO_ALLOCATION_1 = 25e6 ether;
  uint256 public GNOSIS_DAO_ALLOCATION_2 = 50e6 ether;

  uint256 timelockMinDelay;
  address[] timelockProposers;
  address[] timelockExecutors;
  address timeLockAdmin;

  function _deploy(
    address _deployerAddress,
    address _vestingPlansRecipientAddress,
    address _finalHolderOfKpkAddress,
    bool deployOnSepolia
  ) internal {
    // Governance parameters
    //---------------------------------------------------------------------------------------------------------------
    timelockMinDelay = 3600 * 24; // 1 day
    // timelockProposers is a priori empty, but later the role shall be granted to the governor contract
    timelockExecutors.push(address(0)); // Anyone can execute the payloads of already approved proposals

    // TimelockController deployment
    //---------------------------------------------------------------------------------------------------------------
    timelockController =
      new TimelockController(timelockMinDelay, timelockProposers, timelockExecutors, _deployerAddress);

    // Token deployment
    //---------------------------------------------------------------------------------------------------------------
    address kpktokenProxyAddress = Upgrades.deployTransparentProxy(
      'KpkToken.sol',
      address(timelockController), // Owner of the proxy admin
      abi.encodeWithSignature('initialize(address)', _deployerAddress) // The token contract owner is at first the deployer, to be able to create the vesting plans
    );
    kpkToken = KpkToken(kpktokenProxyAddress);

    // Governor contract deployment
    //---------------------------------------------------------------------------------------------------------------
    address kpkGovernorProxyAddress = Upgrades.deployTransparentProxy(
      'KpkGovernor.sol',
      address(timelockController), /* Proxy admin */
      abi.encodeWithSignature('initialize(address,address)', address(kpkToken), address(timelockController))
    );
    kpkGovernor = KpkGovernor(payable(kpkGovernorProxyAddress));

    timelockController.grantRole(timelockController.PROPOSER_ROLE(), kpkGovernorProxyAddress); // Grant proposer/canceller role to Governor contract
    timelockController.grantRole(timelockController.CANCELLER_ROLE(), kpkGovernorProxyAddress); // Grant proposer/canceller role to Governor contract
    timelockController.grantRole(timelockController.DEFAULT_ADMIN_ROLE(), _finalHolderOfKpkAddress); // Grant admin role to safe
    timelockController.renounceRole(timelockController.DEFAULT_ADMIN_ROLE(), _deployerAddress); // Renounce admin role from deployer

    // Vesting plans creation
    //---------------------------------------------------------------------------------------------------------------
    plans.push(
      IBatchPlanner.Plan(
        _vestingPlansRecipientAddress,
        GNOSIS_DAO_ALLOCATION_1,
        1_642_075_200, // The date GIP-20 was approved in Snapshot, i.e. January 13th, 2022, 12:00 UTC
        1_642_075_200, // No cliff, i.e. cliffDate = startDate
        GNOSIS_DAO_ALLOCATION_1 / SECONDS_IN_TWO_YEARS
      )
    );

    plans.push(
      IBatchPlanner.Plan(
        _vestingPlansRecipientAddress,
        GNOSIS_DAO_ALLOCATION_2,
        1_740_706_140 + SECONDS_IN_A_YEAR, // The date GIP-20 was approved in Snapshot + 1 year, i.e. February 28th, 2025, 01:29 UTC + 1 year
        1_740_706_140 + SECONDS_IN_A_YEAR, // No cliff, i.e. cliffDate = startDate
        GNOSIS_DAO_ALLOCATION_2 / SECONDS_IN_TWO_YEARS
      )
    );

    // Meant for Sepolia deployment testing
    tokenVestingPlansAddress = deployOnSepolia ? TOKEN_VESTING_PLANS_SEPOLIA : TOKEN_VESTING_PLANS;
    batchPlannerAddress = deployOnSepolia ? BATCH_PLANNER_SEPOLIA : BATCH_PLANNER;

    // Give irrestricted transfer allowance to the vesting contracts
    kpkToken.transferAllowlist(tokenVestingPlansAddress, true);
    kpkToken.transferAllowlist(batchPlannerAddress, true);

    // Approve the BatchPlanner to spend the KPK tokens
    kpkToken.approve(batchPlannerAddress, GNOSIS_DAO_ALLOCATION_1 + GNOSIS_DAO_ALLOCATION_2);

    // Create the vesting plans depositing the KPK tokens
    IBatchPlanner(batchPlannerAddress).batchVestingPlans(
      tokenVestingPlansAddress,
      address(kpkToken),
      GNOSIS_DAO_ALLOCATION_1 + GNOSIS_DAO_ALLOCATION_2,
      plans,
      1,
      _finalHolderOfKpkAddress,
      true,
      4
    );

    // Transfer the remaining tokens to the karpatkey Treasury Safe
    kpkToken.transfer(_finalHolderOfKpkAddress, kpkToken.balanceOf(_deployerAddress));
    kpkToken.transferOwnership(address(_finalHolderOfKpkAddress));
  }
}

contract DeployTokenSepolia is DeployToken {
  address public _deployerAddress;
  address _vestingPlansRecipientAddress = 0x80e26ecEA683a9d4a5d511c084e1B050C72f15a9;
  address _finalHolderOfKpkAddress = 0x495f9Cd38351A199ac6ff3bB952D0a65DD464736;

  function run() external {
    _deployerAddress = msg.sender;
    vm.startBroadcast();
    _deploy(_deployerAddress, _vestingPlansRecipientAddress, _finalHolderOfKpkAddress, true);
    vm.stopBroadcast();
  }
}

contract DeployTokenMainnet is DeployToken {
  address public _deployerAddress;
  address public _vestingPlansRecipientAddress = GNOSIS_DAO_TREASURY_SAFE;
  address public _finalHolderOfKpkAddress = KPK_TREASURY_SAFE;

  function run() external {
    _deployerAddress = msg.sender;
    vm.startBroadcast();
    _deploy(_deployerAddress, _vestingPlansRecipientAddress, _finalHolderOfKpkAddress, false);
    vm.stopBroadcast();
  }

  function deployToBeUsedForTesting(
    address _testingDeployerAddress
  ) public {
    _deploy(_testingDeployerAddress, _vestingPlansRecipientAddress, _finalHolderOfKpkAddress, false);
  }
}
