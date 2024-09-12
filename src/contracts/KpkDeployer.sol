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
    0x963728b46429c8415acCB03Ac5F5b2A36110d434,
    0xA4FaD769c4c7Af161692D916DE51E6280Dd7d147,
    0x168330c41a77e6737BF32FD16a6f4cFa8B9aa11c,
    0xc07A080BC73E84c3AA8963A40Bd427c78Cf42AE5,
    0xF971D72b812D0Df2Db7D6FeD49c0f5d3CF009411
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

    allocations.push(AllocationData(0x9e951f9b138D57FAb3c3A0685C202F28804611B5, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x5076fA392D5564c95c1CB5cB683470aE3A1eAF9d, 1500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x39D787fdf7384597C7208644dBb6FDa1CcA4eBdf, 5000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xEea91102f78B2EcFc2eEc9868B6523504f9a5241, 2500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xEea91102f78B2EcFc2eEc9868B6523504f9a5241, 2500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x2bdC69b3E175154bD1E8D4Be50e1a51CffB721Bf, 500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xe705b1D26B85c9F9f91A3690079D336295F14F08, 2500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x22Be67f0715835526a06a227ba9c8AffA3F7FE5f, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xac140648435d03f784879cd789130F22Ef588Fcd, 500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xB1f881f47baB744E7283851bC090bAA626df931d, 500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xa361f522eC77c3213C7E435160a38DB1Fc45EDcc, 250 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xcE024Ad2997Aad42112E789188da62E4bE5bA05D, 200 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x99E4256100552Bfc3a22AC92561f26cb9637bEA1, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x556Bd626535022cB854e297ADa4F46807da54B2c, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x0306E34A687798A63A42B506F32CB5A57c95D187, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x436f2b24D1052F14B4a7e095438a22b09F706C21, 200 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x19dBf30453d8528bFD0be878535e15715CFFF066, 250 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xE91F64cA1da165Ca8437686B69A022156550837B, 100 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x6F86e116C2E2fAe0404276ca1C2aA1F074626396, 200 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xa31f48CF048af2c6851c50E7d60a32296A01119b, 200 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x75dbc56888c676626a7Ec0e128af46f6F5B494d2, 750 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xc174b29C50d14303063a0E802B325a676AE2a853, 10_000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xcb68110C43C97b6051FEd5e2Bacc2814aDaD1688, 250 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x371880c69B9442888318e82B079BC41d85f03979, 1875 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x56264e5ec5215C3974Cfb550D3aeFA6720f5eE9D, 1875 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x418592317dCEc824603c6840E51E9c2f2B5c8156, 1000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x6e0a1dDAD894e6466d405Bb73377F0A257278D74, 2000 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xFB014896319E1650FD1426A6A4f070e9286f46F1, 1250 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x22915193F2BDe0DA4dfE317BfCE4Ddf1b6f13DE9, 500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0x74fEa3FB0eD030e9228026E7F413D66186d3D107, 500 ether, 1_718_968_487, false));
    allocations.push(AllocationData(0xE61A0e34a63f121351DAd37Cd96784165A22AA5E, 250 ether, 1_718_968_487, false));

    allocations.push(AllocationData(0x849D52316331967b6fF1198e5E32A0eB168D039d, 25_000 ether, 1_642_075_200, false));
    allocations.push(AllocationData(0x849D52316331967b6fF1198e5E32A0eB168D039d, 75_000 ether, block.timestamp, false));

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
