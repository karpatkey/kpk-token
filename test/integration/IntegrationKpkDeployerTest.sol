// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';

import {KpkDeployer} from 'contracts/KpkDeployer.sol';
import {karpatkeyToken} from 'contracts/karpatkeyToken.sol';
import {Vm} from 'forge-std/Test.sol';

contract IntegrationKpkDeployerTest is ForkTest {
  IDeployer2 deployer;
  ICreateCall deployerSafe;
  ITokenVestingPlans tokenVestingPLans;

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

  function setUp() public {
    _forkSetupBefore();
    deployer = IDeployer2(0x8D85e7c9A4e369E53Acc8d5426aE1568198b0112); // Simple create2 deployer from Yearn
    deployerSafe = ICreateCall(0x7cbB62EaA69F79e6873cD1ecB2392971036cFAa4); // Simple create deployer from Safe
    tokenVestingPLans = ITokenVestingPlans(0x2CDE9919e81b20B4B33DD562a48a84b54C48F00C);
  }

  function testDeployer() public {
    address tokenOwner = 0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4;
    //bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'), args);
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'));

    vm.recordLogs();

    //deployer.deploy(bytecode, 0x035515);
    deployerSafe.performCreate(0, bytecode);

    Vm.Log[] memory entries = vm.getRecordedLogs();

    (address governanceSafe,) = abi.decode(entries[1].data, (address, address));

    assertEq(entries[0].topics[0], keccak256('SafeSetup(address,address[],uint256,address,address)'));
    (address[] memory owners, uint256 threshold,,) = abi.decode(entries[0].data, (address[], uint256, address, address));
    assertEq(owners, GOVERNANCE_SAFE_OWNERS);
    assertEq(threshold, THRESHOLD);

    karpatkeyToken kpkToken = karpatkeyToken(entries[3].emitter);
    assertEq(kpkToken.owner(), governanceSafe);

    uint256 planId = uint256(entries[21].topics[1]);
    address planRecipient = abi.decode(abi.encodePacked(entries[21].topics[2]), (address));
    assertEq(planRecipient, tokenOwner);
    address planToken = abi.decode(abi.encodePacked(entries[21].topics[3]), (address));
    assertEq(planToken, address(kpkToken));

    (address token, uint256 amount,,,,,,) = tokenVestingPLans.plans(planId);

    assertEq(token, address(kpkToken));
    assertEq(amount, 24 ether);

    vm.startPrank(tokenOwner);
    uint256[] memory planIds = new uint256[](1);
    planIds[0] = planId;
    tokenVestingPLans.redeemPlans(planIds);
    assertEq(kpkToken.balanceOf(tokenOwner), 24 ether);
  }
}

interface IDeployer2 {
  function deploy(bytes memory code, uint256 salt) external returns (address);
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
