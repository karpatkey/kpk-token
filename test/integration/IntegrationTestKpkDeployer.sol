// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {KpkDeployer} from 'contracts/KpkDeployer.sol';
import {
  GNOSIS_DAO_TREASURY_SAFE,
  ISafeCreateCall,
  ITokenVestingPlans,
  KARPATKEY_TREASURY_SAFE,
  SAFE_CREATE_CALL,
  SECONDS_IN_A_YEAR,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS
} from 'contracts/KpkDeployerLib.sol';
import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

import {Vm} from 'forge-std/Test.sol';

contract IntegrationTestKpkDeployer is ForkTest {
  ITokenVestingPlans tokenVestingPlans;

  KpkDeployer kpkDeployer;
  KpkToken kpkToken;
  KpkGovernor kpkGovernor;
  TimelockController timelockController;

  function setUp() public {
    _forkSetupBefore();
  }

  struct AllocationData {
    address recipient;
    uint256 amount;
    uint256 start;
  }

  function testDeployer() public {
    // Specify the desired owner for KpkDeployer (it must be the one calling deploy())
    address givenOwner = address(0x123);

    // Append the constructor parameter (owner address) to the bytecode.
    // This is necessary because KpkDeployer’s constructor takes an address.
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'), abi.encode(givenOwner));

    // Deploy the KpkDeployer contract with the provided owner.
    // (Using safeCreateCall.performCreate as in your original test)
    kpkDeployer = KpkDeployer(address(safeCreateCall.performCreate(0, bytecode)));

    // Since deploy() is protected by onlyOwner, start impersonating the owner.
    vm.startPrank(givenOwner);
    (
      address timelockControllerAddress,
      address kpkTokenImplAddress,
      address kpkTokenProxyAddress,
      address kpkGovernorImplAddress,
      address kpkGovernorProxyAddress
    ) = kpkDeployer.deploy();
    vm.stopPrank();

    kpkToken = KpkToken(kpkTokenProxyAddress);
    kpkGovernor = KpkGovernor(payable(kpkGovernorProxyAddress));
    timelockController = TimelockController(payable(timelockControllerAddress));

    // Pre-allocate an array of size 2 in memory
    AllocationData[] memory allocations = new AllocationData[](2);

    allocations[0] = AllocationData(GNOSIS_DAO_TREASURY_SAFE, 25_000_000 ether, 1_642_075_200);
    allocations[1] = AllocationData(GNOSIS_DAO_TREASURY_SAFE, 75_000_000 ether, block.timestamp + SECONDS_IN_A_YEAR);

    vm.recordLogs();

    ///------------------------------------------------------------------------
    /// Fetch fixed data from the KpkDeployer contract
    tokenVestingPlans = ITokenVestingPlans(TOKEN_VESTING_PLANS);

    KpkToken kpkToken = KpkToken(kpkDeployer.kpkTokenAddress());

    ///------------------------------------------------------------------------

    Vm.Log[] memory entries = vm.getRecordedLogs();

    bytes32 planCreatedTopic =
      keccak256('PlanCreated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256,address,bool)');

    // Loop through the entries to find and verify each PlanCreated event
    uint256[] memory planIds = new uint256[](1);
    uint256 j = 0;
    for (uint256 i = 0; i < entries.length; i++) {
      if (entries[i].topics[0] == planCreatedTopic) {
        uint256 planId = uint256(entries[i].topics[1]);
        address planRecipient = abi.decode(abi.encodePacked(entries[i].topics[2]), (address));
        address planToken = abi.decode(abi.encodePacked(entries[i].topics[3]), (address));

        // Verify the PlanCreated event details
        assertEq(planRecipient, allocations[j].recipient);
        assertEq(planToken, address(kpkToken));

        (
          address tokenAddress,
          uint256 amountPlan,
          uint256 startPlan,
          uint256 cliff,
          uint256 rate,
          uint256 period,
          address vestingAdmin,
          bool adminTransferOBO
        ) = tokenVestingPlans.plans(planId);
        assertEq(tokenAddress, address(kpkToken));
        assertEq(amountPlan, allocations[j].amount);
        assertEq(startPlan, allocations[j].start);
        assertEq(cliff, allocations[j].start);
        assertEq(rate, allocations[j].amount / SECONDS_IN_TWO_YEARS);
        assertEq(period, 1);
        assertEq(vestingAdmin, KARPATKEY_TREASURY_SAFE);
        assertEq(adminTransferOBO, true);

        // Redeem the plan and verify the balance
        vm.startPrank(allocations[j].recipient);
        planIds[0] = planId;
        uint256 initialBalance = kpkToken.balanceOf(allocations[j].recipient);
        tokenVestingPlans.redeemPlans(planIds);

        assertEq(
          kpkToken.balanceOf(allocations[j].recipient),
          initialBalance
            + (
              block.timestamp < cliff
                ? 0
                : (
                  (block.timestamp - allocations[j].start) > SECONDS_IN_TWO_YEARS
                    ? allocations[j].amount
                    : (allocations[j].amount / SECONDS_IN_TWO_YEARS * (block.timestamp - allocations[j].start))
                )
            )
        );
        vm.stopPrank();
        j++;
      }
    }
    assertEq(kpkToken.transferAllowlisted(KARPATKEY_TREASURY_SAFE), true);
  }
}
