// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {karpatkeyToken} from './karpatkeyToken.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

address constant BATCH_PLANNER_1 = 0x3466EB008EDD8d5052446293D1a7D212cb65C646;
address constant TOKEN_VESTING_PLANS_1 = 0x2CDE9919e81b20B4B33DD562a48a84b54C48F00C;

address constant BATCH_PLANNER_155 = 0xd8B085f666299E52f24e637aB1076ba5C2c38045;
address constant TOKEN_VESTING_PLANS_155 = 0x68b6986416c7A38F630cBc644a2833A0b78b3631;

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

  /// @notice Address of the BatchPlanner contract
  address public BATCH_PLANNER = BATCH_PLANNER_1;
  /// @notice Address of the TokenVestingPlans contract
  address public TOKEN_VESTING_PLANS = TOKEN_VESTING_PLANS_1;
  /// @notice The duration of the 1.5 years cliff in seconds
  uint256 public CLIFF_IN_SECONDS = 47_304_000;

  uint256 public SECONDS_IN_TWO_YEARS = 63_072_000;

  address public KARPATKEY_TREASURY_SAFE = 0x58e6c7ab55Aa9012eAccA16d1ED4c15795669E1C;

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

  AllocationData[] public allocations;
  IBatchPlanner.Plan[] public plans;

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

    karpatkeyToken impl = new karpatkeyToken();
    karpatkeyToken kpkToken = karpatkeyToken(
      address(
        new TransparentUpgradeableProxy(
          address(impl),
          karpatkeyGovernanceSafe,
          abi.encodeWithSignature('initialize(address)', address(this)) // initialize the token
        )
      )
    );

    uint256 totalAllocation = 0;

    allocations.push(AllocationData(0x0c538646c66294D5B7a4051b2F7b8C66edE86d5c, 22 ether, 1_626_038_149, false));
    allocations.push(AllocationData(0x7F980d40A47446A49A12af4DF6f0E1486F23a766, 3 ether, 1_638_822_635, false));
    allocations.push(AllocationData(0xAfFEbBd3632737c125aed963483BA63C8304e21B, 6 ether, 1_639_019_390, false));
    allocations.push(AllocationData(0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4, 6785 ether, 1_639_003_638, false));
    allocations.push(AllocationData(0x0c538646c66294D5B7a4051b2F7b8C66edE86d5c, 40_922 ether, 1_625_195_311, true));
    allocations.push(AllocationData(0xAfFEbBd3632737c125aed963483BA63C8304e21B, 5278 ether, 1_638_001_938, false));
    allocations.push(AllocationData(0x2b761C22d8695376550c2c05e773EEE1d7508426, 46_753 ether, 1_625_290_887, true));
    allocations.push(AllocationData(0x7F980d40A47446A49A12af4DF6f0E1486F23a766, 7791 ether, 1_636_997_605, false));
    allocations.push(AllocationData(0x7F980d40A47446A49A12af4DF6f0E1486F23a766, 36 ether, 1_637_235_452, true));
    allocations.push(AllocationData(0xAfFEbBd3632737c125aed963483BA63C8304e21B, 56 ether, 1_637_844_815, true));
    allocations.push(AllocationData(0x7F980d40A47446A49A12af4DF6f0E1486F23a766, 4 ether, 1_638_405_180, false));
    allocations.push(AllocationData(0x2b761C22d8695376550c2c05e773EEE1d7508426, 23 ether, 1_623_664_107, false));
    allocations.push(AllocationData(0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4, 36 ether, 1_638_362_591, true));
    allocations.push(AllocationData(0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4, 4 ether, 1_638_961_142, false));
    allocations.push(AllocationData(0xdAEc4b65BA27265f1A5c31f19F0396852A924Df4, 2 ether, 1_638_727_940, false));
    allocations.push(AllocationData(0xAfFEbBd3632737c125aed963483BA63C8304e21B, 2 ether, 1_638_341_136, false));

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
      kpkToken.increaseTransferAllowance(TOKEN_VESTING_PLANS, allocations[i].recipient, allocations[i].amount);
    }
    kpkToken.approve(BATCH_PLANNER, totalAllocation);
    kpkToken.increaseTransferAllowance(BATCH_PLANNER, TOKEN_VESTING_PLANS, totalAllocation);

    IBatchPlanner(BATCH_PLANNER).batchVestingPlans(
      TOKEN_VESTING_PLANS, address(kpkToken), totalAllocation, plans, 1, karpatkeyGovernanceSafe, true, 4
    );

    // Transfer the remaining tokens to the karpatkey Governance Safe
    kpkToken.transfer(KARPATKEY_TREASURY_SAFE, kpkToken.balanceOf(address(this)));
    kpkToken.transferAllowlist(KARPATKEY_TREASURY_SAFE, true);
    kpkToken.transferOwnership(karpatkeyGovernanceSafe);
  }

  function getNumberOfGovernanceSafeOwners() public view returns (uint256) {
    return GOVERNANCE_SAFE_OWNERS.length;
  }
}
