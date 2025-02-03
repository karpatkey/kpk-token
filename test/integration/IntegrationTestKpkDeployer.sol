// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {KpkDeployer} from 'contracts/KpkDeployer.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

import {
  CLIFF_IN_SECONDS,
  ISafeCreateCall,
  ITokenVestingPlans,
  KARPATKEY_TREASURY_SAFE,
  SAFE_CREATE_CALL,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS
} from 'contracts/KpkDeployerLib.sol';
import {Vm} from 'forge-std/Test.sol';

contract IntegrationTestKpkDeployer is ForkTest {
  ITokenVestingPlans tokenVestingPlans;

  KpkDeployer kpkDeployer;

  function setUp() public {
    _forkSetupBefore();
  }

  function testDeployer() public {
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'));

    vm.recordLogs();

    kpkDeployer = KpkDeployer(address(safeCreateCall.performCreate(0, bytecode)));

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

        // Get the corresponding allocation details
        (address tokenOwner, uint256 amount, uint256 start, bool cliffBool) = kpkDeployer.allocations(j);
        j++;
        // Verify the PlanCreated event details
        assertEq(planRecipient, tokenOwner);
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
        assertEq(amountPlan, amount);
        assertEq(startPlan, start);
        assertEq(cliff, cliffBool ? start + CLIFF_IN_SECONDS : start);
        assertEq(rate, amount / SECONDS_IN_TWO_YEARS);
        assertEq(period, 1);
        assertEq(vestingAdmin, KARPATKEY_TREASURY_SAFE);
        assertEq(adminTransferOBO, true);

        // Redeem the plan and verify the balance
        vm.startPrank(tokenOwner);
        planIds[0] = planId;
        uint256 initialBalance = kpkToken.balanceOf(tokenOwner);
        tokenVestingPlans.redeemPlans(planIds);

        assertEq(
          kpkToken.balanceOf(tokenOwner),
          initialBalance
            + (
              block.timestamp < cliff
                ? 0
                : (
                  (block.timestamp - start) > SECONDS_IN_TWO_YEARS
                    ? amount
                    : (amount / SECONDS_IN_TWO_YEARS * (block.timestamp - start))
                )
            )
        );
        vm.stopPrank();
      }
    }
    assertEq(kpkToken.transferAllowlisted(KARPATKEY_TREASURY_SAFE), true);
  }
}
