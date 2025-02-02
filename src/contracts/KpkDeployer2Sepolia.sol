// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {KpkGovernor} from 'contracts/KpkGovernor.sol';
import {KpkToken} from 'contracts/KpkToken.sol';
import {TimelockController} from 'contracts/TimelockController.sol';

address constant BATCH_PLANNER = 0xd8B085f666299E52f24e637aB1076ba5C2c38045; // Sepolia address

address constant SAFE_PROXY_FACTORY = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;

interface ISafeProxyFactory {
  function createProxyWithNonce(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce
  ) external returns (address proxy);
}

interface IBatchPlanner {
  struct Plan {
    address recipient;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
  }

  /// @notice function to create a batch of vesting plans.
  /// @dev the function will pull in the entire balance of totalAmount to the contract, increase the allowance and then via loop mint vesting plans
  /// @param locker is the address of the lockup plan that the tokens will be locked in, and NFT plan provided to
  /// @param token is the address of the token that is given and locked to the individuals
  /// @param totalAmount is the total amount of tokens being locked, this has to equal the sum of all the individual amounts in the plans struct
  /// @param plans is the array of plans that contain each plan parameters
  /// @param period is the length of the period in seconds that tokens become unlocked / vested
  /// @param vestingAdmin is the address of the vesting admin, that will be the same for all plans created
  /// @param adminTransferOBO is an emergency toggle that allows the vesting admin to tranfer a vesting plan on behalf of a beneficiary
  /// @param mintType is an internal tool to help with identifying front end applications
  function batchVestingPlans(
    address locker,
    address token,
    uint256 totalAmount,
    Plan[] calldata plans,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO,
    uint8 mintType
  ) external;
}

contract KpkDeployer {
  struct AllocationData {
    address recipient;
    uint256 amount;
    uint256 start;
    bool cliffBool;
  }

  /// @notice The duration of the 1.5 years cliff in seconds
  uint256 public CLIFF_IN_SECONDS = 47_304_000;

  uint256 public SECONDS_IN_TWO_YEARS = 63_072_000;
  address public TOKEN_VESTING_PLANS = 0x68b6986416c7A38F630cBc644a2833A0b78b3631;
  address public KARPATKEY_TREASURY_SAFE = 0xbdAed5545b57b0b783D98c1Dd14C23975F2495bC; //Dummy deployer

  address[] public GOVERNANCE_SAFE_OWNERS = [
    0x963728b46429c8415acCB03Ac5F5b2A36110d434,
    0xA4FaD769c4c7Af161692D916DE51E6280Dd7d147,
    0x168330c41a77e6737BF32FD16a6f4cFa8B9aa11c,
    0xc07A080BC73E84c3AA8963A40Bd427c78Cf42AE5,
    0xF971D72b812D0Df2Db7D6FeD49c0f5d3CF009411,
    0x0D50c737f102703fdBac7A6829EaD7FE3b20561A,
    0xF0a88b5aB06E56e0a1e4c6259f4986551200Bb3c,
    0x1a30824cfBb571Ca92Bc8e11BecfF0d9a42b5a49,
    0x72DDE1ee3E91945DF444B9AE4B97B55D66FA858C
  ];
  uint256 public THRESHOLD = 5;

  AllocationData[] public allocations;
  IBatchPlanner.Plan[] public plans;

  uint256 public MIN_DELAY = 60;
  address[] public PROPOSERS;
  address[] public EXECUTORS;
  address public TIMELOCK_CONTROLLER_ADMIN;

  constructor() {
    ISafeProxyFactory safeProxyFactory;
    safeProxyFactory = ISafeProxyFactory(SAFE_PROXY_FACTORY);
    address karpatkeyGovernanceSafe = address(
      safeProxyFactory.createProxyWithNonce(
        0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
        abi.encodeWithSignature(
          'setup(address[],uint256,address,bytes,address,address,uint256,address)',
          GOVERNANCE_SAFE_OWNERS,
          THRESHOLD,
          address(0),
          bytes('0x'),
          0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
          address(0),
          0,
          address(0)
        ),
        block.timestamp
      )
    );

    KpkToken kpkTokenImpl = new KpkToken();
    address kpkTokenProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkTokenImpl), karpatkeyGovernanceSafe, abi.encodeWithSignature('initialize(address)', address(this))
      )
    );

    KpkToken kpkToken = KpkToken(kpkTokenProxyAddress);

    PROPOSERS.push(karpatkeyGovernanceSafe);
    EXECUTORS.push(karpatkeyGovernanceSafe);
    TIMELOCK_CONTROLLER_ADMIN = karpatkeyGovernanceSafe;

    TimelockController timelockControllerImpl = new TimelockController();
    address timelockControllerProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(timelockControllerImpl),
        TIMELOCK_CONTROLLER_ADMIN,
        abi.encodeWithSignature(
          'initialize(uint256,address[],address[],address)', MIN_DELAY, PROPOSERS, EXECUTORS, TIMELOCK_CONTROLLER_ADMIN
        )
      )
    );

    TimelockController timelockController = TimelockController(payable(timelockControllerProxyAddress));

    KpkGovernor kpkGovernorImpl = new KpkGovernor();
    address kpkGovernorProxyAddress = address(
      new TransparentUpgradeableProxy(
        address(kpkGovernorImpl),
        karpatkeyGovernanceSafe,
        abi.encodeWithSignature('initialize(address,address)', address(kpkToken), address(timelockController))
      )
    );

    KpkGovernor kpkGovernor = KpkGovernor(payable(kpkGovernorProxyAddress));

    uint256 totalAllocation = 0;

    allocations.push(
      AllocationData(0x80e26ecEA683a9d4a5d511c084e1B050C72f15a9, 1000 ether, block.timestamp - 30 * 24 * 3600, false)
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
      TOKEN_VESTING_PLANS, address(kpkToken), totalAllocation, plans, 1, karpatkeyGovernanceSafe, true, 4
    );

    // Transfer the remaining tokens to the karpatkey Treasury Safe
    kpkToken.transfer(KARPATKEY_TREASURY_SAFE, kpkToken.balanceOf(address(this)));
    kpkToken.transferAllowlist(KARPATKEY_TREASURY_SAFE, true);
    kpkToken.transferOwnership(karpatkeyGovernanceSafe);
  }

  function getNumberOfGovernanceSafeOwners() public view returns (uint256) {
    return GOVERNANCE_SAFE_OWNERS.length;
  }
}
