// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {KpkDeployer} from 'contracts/KpkDeployer2.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
import {Vm} from 'forge-std/Test.sol';

contract IntegrationTestKpkDeployer2Mainnet is ForkTest {
  ICreateCall deployerSafe;
  ITokenVestingPlans tokenVestingPlans;

  KpkDeployer kpkDeployer;

  function setUp() public {
    _forkSetupBefore();
    deployerSafe = ICreateCall(0x7cbB62EaA69F79e6873cD1ecB2392971036cFAa4); // Simple create deployer from Safe
  }

  function testDeployer() public {
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer2.sol:KpkDeployer'));

    vm.recordLogs();

    kpkDeployer = KpkDeployer(address(deployerSafe.performCreate(0, bytecode)));

    ///------------------------------------------------------------------------
    /// Fetch fixed data from the KpkDeployer contract

    uint256 CLIFF_IN_SECONDS = kpkDeployer.CLIFF_IN_SECONDS();
    uint256 SECONDS_IN_TWO_YEARS = kpkDeployer.SECONDS_IN_TWO_YEARS();

    uint256 numberOfOwners = kpkDeployer.getNumberOfGovernanceSafeOwners();
    address[] memory GOVERNANCE_SAFE_OWNERS = new address[](numberOfOwners);

    for (uint256 i = 0; i < numberOfOwners; i++) {
      GOVERNANCE_SAFE_OWNERS[i] = kpkDeployer.GOVERNANCE_SAFE_OWNERS(i);
    }
    uint256 THRESHOLD = kpkDeployer.THRESHOLD();

    tokenVestingPlans = ITokenVestingPlans(kpkDeployer.TOKEN_VESTING_PLANS());

    address KARPATKEY_TREASURY_SAFE = kpkDeployer.KARPATKEY_TREASURY_SAFE();

    ///------------------------------------------------------------------------

    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries[0].topics[0], keccak256('SafeSetup(address,address[],uint256,address,address)'));
    (address[] memory owners, uint256 threshold,,) = abi.decode(entries[0].data, (address[], uint256, address, address));
    assertEq(owners, GOVERNANCE_SAFE_OWNERS);
    assertEq(threshold, THRESHOLD);

    assertEq(entries[1].topics[0], keccak256('ProxyCreation(address,address)'));
    (address governanceSafe,) = abi.decode(entries[1].data, (address, address));

    assertEq(entries[3].topics[0], keccak256('Upgraded(address)'));
    KpkToken kpkToken = KpkToken(entries[3].emitter);
    assertEq(kpkToken.owner(), governanceSafe);

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
        assertEq(vestingAdmin, governanceSafe);
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

interface ICreateCall {
  function performCreate(uint256 value, bytes memory deploymentData) external returns (address newContract);
}

interface ITokenVestingPlans {
  function redeemPlans(
    uint256[] memory planIds
  ) external;

  function plans(
    uint256 planId
  ) external view returns (address, uint256, uint256, uint256, uint256, uint256, address, bool);
}
