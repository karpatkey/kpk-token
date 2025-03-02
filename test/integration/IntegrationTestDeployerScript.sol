// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {
  GNOSIS_DAO_TREASURY_SAFE,
  ITokenVestingPlans,
  KPK_TREASURY_SAFE,
  SECONDS_IN_A_YEAR,
  SECONDS_IN_TWO_YEARS,
  TOKEN_VESTING_PLANS
} from 'contracts/KpkDeployerLib.sol';

import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';

import {Vm} from 'forge-std/Test.sol';
import {DeployToken, DeployTokenMainnet} from 'script/Deploy.sol';

contract IntegrationTestDeployerScript is ForkTest {
  ITokenVestingPlans tokenVestingPlans;
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

  function testDeployTokenMainnet() public {
    // Deployment with recorded logs
    //---------------------------------------------------------------------------------------------------------------
    vm.recordLogs();

    DeployTokenMainnet deployTokenMainnet = new DeployTokenMainnet();
    address deployerAddress = address(deployTokenMainnet);

    deployTokenMainnet.deployToBeUsedForTesting(deployerAddress);

    Vm.Log[] memory entries = vm.getRecordedLogs();

    // Token checks
    //---------------------------------------------------------------------------------------------------------------
    kpkToken = deployTokenMainnet.kpkToken();
    assertEq(kpkToken.owner(), KPK_TREASURY_SAFE);
    assertEq(kpkToken.balanceOf(KPK_TREASURY_SAFE), 1000e6 ether - 25e6 ether - 50e6 ether);

    // Governor checks
    //---------------------------------------------------------------------------------------------------------------
    kpkGovernor = deployTokenMainnet.kpkGovernor();
    assertEq(address(kpkGovernor.token()), address(kpkToken));
    assertEq(kpkGovernor.timelock(), address(deployTokenMainnet.timelockController()));
    assertEq(kpkGovernor.votingDelay(), 7200);
    assertEq(kpkGovernor.votingPeriod(), 36_000);
    assertEq(kpkGovernor.proposalThreshold(), 1e6 ether);
    assertEq(kpkGovernor.quorumNumerator(), 4);
    assertEq(kpkGovernor.quorumDenominator(), 100);

    // TimelockController checks
    //---------------------------------------------------------------------------------------------------------------
    timelockController = deployTokenMainnet.timelockController();
    assertEq(timelockController.getMinDelay(), 3600 * 24);
    assertTrue(
      timelockController.hasRole(0x0000000000000000000000000000000000000000000000000000000000000000, KPK_TREASURY_SAFE)
    );
    assertTrue(
      timelockController.hasRole(0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63, address(0))
    );
    assertTrue(
      timelockController.hasRole(
        0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1, address(kpkGovernor)
      )
    );
    assertTrue(
      timelockController.hasRole(
        0xfd643c72710c63c0180259aba6b2d05451e3591a24e58b62239378085726f783, address(kpkGovernor)
      )
    );

    // Proxy admins checks
    //------------------------------------------------------------------------------------------------
    bytes32 proxyAdminChangedTopic = keccak256('AdminChanged(address,address)');
    for (uint256 i = 0; i < entries.length; i++) {
      if (entries[i].topics[0] == proxyAdminChangedTopic) {
        (, address newAdmin) = abi.decode(entries[i].data, (address, address));
        assertEq(IProxyAdmin(newAdmin).owner(), address(timelockController));
      }
    }

    // Vesting plans checks
    //---------------------------------------------------------------------------------------------------------------
    tokenVestingPlans = ITokenVestingPlans(deployTokenMainnet.tokenVestingPlansAddress());

    // Pre-allocate an array of size 2 in memory
    AllocationData[] memory allocations = new AllocationData[](2);

    allocations[0] = AllocationData(GNOSIS_DAO_TREASURY_SAFE, 25e6 ether, 1_642_075_200);
    allocations[1] = AllocationData(GNOSIS_DAO_TREASURY_SAFE, 50e6 ether, 1_740_706_140 + SECONDS_IN_A_YEAR);

    ///------------------------------------------------------------------------

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
        assertEq(vestingAdmin, KPK_TREASURY_SAFE);
        assertEq(adminTransferOBO, true);

        // Redeem the plan and verify the balance
        vm.startPrank(allocations[j].recipient);
        planIds[0] = planId;
        uint256 initialBalance = deployTokenMainnet.kpkToken().balanceOf(allocations[j].recipient);
        tokenVestingPlans.redeemPlans(planIds);

        assertEq(
          deployTokenMainnet.kpkToken().balanceOf(allocations[j].recipient),
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
        j++;
      }
    }
  }
}

interface IProxyAdmin {
  function owner() external view returns (address);
}
