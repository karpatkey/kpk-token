// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ForkTest} from './ForkTest.sol';
import {KpkDeployer} from 'contracts/KpkDeployer.sol';

contract KpkDeployerTest is ForkTest {
  IDeployer2 deployer;
  ICreateCall deployerSafe;

  function setUp() public {
    _forkSetupBefore();
    deployer = IDeployer2(0x8D85e7c9A4e369E53Acc8d5426aE1568198b0112); // Simple create2 deployer from Yearn
    deployerSafe = ICreateCall(0x7cbB62EaA69F79e6873cD1ecB2392971036cFAa4); // Simple create deployer from Safe
  }

  function testDeployer() public {
    //bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'), args);
    bytes memory bytecode = abi.encodePacked(vm.getCode('KpkDeployer.sol:KpkDeployer'));

    //deployer.deploy(bytecode, 0x035515);
    deployerSafe.performCreate(0, bytecode);
  }
}

interface IDeployer2 {
  function deploy(bytes memory code, uint256 salt) external returns (address);
}

interface ICreateCall {
  function performCreate(uint256 value, bytes memory deploymentData) external returns (address newContract);
}
