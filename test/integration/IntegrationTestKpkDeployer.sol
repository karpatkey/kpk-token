// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {KpkDeployer} from 'contracts/KpkDeployer.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {Vm} from 'forge-std/Test.sol';

contract IntegrationKpkDeployerTest is ForkTest {
  ICreateCall deployerSafe;
  ITokenVestingPlans tokenVestingPlans;

  address[] public GOVERNANCE_SAFE_OWNERS = [
    0x29C3E0263B6a2EF34E2c526e40Ce4B6C4542b52c,
    0x7D7bd02d8c73234926b8db019252a15AE20B5121,
    0x72DDE1ee3E91945DF444B9AE4B97B55D66FA858C,
    0x5eaef45355c19D486c0Fed388F09B767307e70d4,
    0x1a30824cfBb571Ca92Bc8e11BecfF0d9a42b5a49,
    0xB312B894841F7fA1BC0Ff736D449E98AdD9c72E6,
    0xF86BA96c6663D4cA552a2ADc24850c680ee471a5,
    0xD539678E7dB4cD9e3320aE0baE36370D28F4c2C3,
    0xc267513Eac792F31db3a87bd93E32cE7e9F8fCf2
  ];
  uint256 public THRESHOLD = 5;

  /// @notice The duration of the 1.5 years cliff in seconds
  uint256 public CLIFF_IN_SECONDS = 47_304_000;

  uint256 public SECONDS_IN_TWO_YEARS = 63_072_000;

  function setUp() public {
    _forkSetupBefore();
    deployerSafe = ICreateCall(0x7cbB62EaA69F79e6873cD1ecB2392971036cFAa4); // Simple create deployer from Safe
    tokenVestingPlans = ITokenVestingPlans(0x2CDE9919e81b20B4B33DD562a48a84b54C48F00C);
  }

  function testDeployer() public {
    address tokenOwner_1 = 0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4;
    uint256 amount_1 = 24 ether;
    uint256 start_1 = 1_636_675_200;
    address tokenOwner_2 = 0x495f9Cd38351A199ac6ff3bB952D0a65DD464736;
    uint256 amount_2 = 12 ether;
    uint256 start_2 = block.timestamp - (365 + 10 * 30) * 24 * 3600;
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'));

    vm.recordLogs();

    deployerSafe.performCreate(0, bytecode);

    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries[0].topics[0], keccak256('SafeSetup(address,address[],uint256,address,address)'));
    (address[] memory owners, uint256 threshold,,) = abi.decode(entries[0].data, (address[], uint256, address, address));
    assertEq(owners, GOVERNANCE_SAFE_OWNERS);
    assertEq(threshold, THRESHOLD);

    assertEq(entries[1].topics[0], keccak256('ProxyCreation(address,address)'));
    (address governanceSafe,) = abi.decode(entries[1].data, (address, address));

    assertEq(entries[3].topics[0], keccak256('Upgraded(address)'));
    karpatkeyToken kpkToken = karpatkeyToken(entries[3].emitter);
    assertEq(kpkToken.owner(), governanceSafe);

    assertEq(
      entries[20].topics[0],
      keccak256('PlanCreated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256,address,bool)')
    );
    uint256 planId_1 = uint256(entries[20].topics[1]);
    address planRecipient_1 = abi.decode(abi.encodePacked(entries[20].topics[2]), (address));
    assertEq(planRecipient_1, tokenOwner_1);
    address planToken_1 = abi.decode(abi.encodePacked(entries[20].topics[3]), (address));
    assertEq(planToken_1, address(kpkToken));
    (
      address tokenAddress_1,
      uint256 amountPlan_1,
      uint256 startPlan_1,
      uint256 cliff_1,
      uint256 rate_1,
      uint256 period_1,
      address vestingAdmin_1,
      bool adminTransferOBO_1
    ) = tokenVestingPlans.plans(planId_1);
    assertEq(tokenAddress_1, address(kpkToken));
    assertEq(amountPlan_1, amount_1);
    assertEq(startPlan_1, start_1);
    assertEq(cliff_1, start_1 + CLIFF_IN_SECONDS);
    assertEq(rate_1, amount_1 / SECONDS_IN_TWO_YEARS);
    assertEq(period_1, 1);
    assertEq(vestingAdmin_1, governanceSafe);
    assertEq(adminTransferOBO_1, true);

    assertEq(
      entries[25].topics[0],
      keccak256('PlanCreated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256,address,bool)')
    );
    uint256 planId_2 = uint256(entries[25].topics[1]);
    address planRecipient_2 = abi.decode(abi.encodePacked(entries[25].topics[2]), (address));
    assertEq(planRecipient_2, tokenOwner_2);
    address planToken_2 = abi.decode(abi.encodePacked(entries[25].topics[3]), (address));
    assertEq(planToken_2, address(kpkToken));
    (
      address tokenAddress_2,
      uint256 amountPlan_2,
      uint256 startPlan_2,
      uint256 cliff_2,
      uint256 rate_2,
      uint256 period_2,
      address vestingAdmin_2,
      bool adminTransferOBO_2
    ) = tokenVestingPlans.plans(planId_2);
    assertEq(tokenAddress_2, address(kpkToken));
    assertEq(amountPlan_2, amount_2);
    assertEq(startPlan_2, start_2);
    assertEq(cliff_2, start_2);
    assertEq(rate_2, amount_2 / SECONDS_IN_TWO_YEARS);
    assertEq(period_2, 1);
    assertEq(vestingAdmin_2, governanceSafe);
    assertEq(adminTransferOBO_2, true);

    vm.startPrank(tokenOwner_1);
    uint256[] memory planIds = new uint256[](1);
    planIds[0] = planId_1;
    tokenVestingPlans.redeemPlans(planIds);
    assertEq(kpkToken.balanceOf(tokenOwner_1), amount_1);

    vm.startPrank(tokenOwner_2);
    uint256[] memory planIds_2 = new uint256[](1);
    planIds_2[0] = planId_2;
    tokenVestingPlans.redeemPlans(planIds_2);
    assertEq(kpkToken.balanceOf(tokenOwner_2), amount_2 / SECONDS_IN_TWO_YEARS * (block.timestamp - start_2));
  }
}

interface ICreateCall {
  function performCreate(uint256 value, bytes memory deploymentData) external returns (address newContract);
}

interface ITokenVestingPlans {
  function redeemPlans(uint256[] memory planIds) external;

  function plans(uint256 planId)
    external
    view
    returns (address, uint256, uint256, uint256, uint256, uint256, address, bool);
}
