// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant CLIFF_IN_SECONDS = 47_304_000;
uint256 constant SECONDS_IN_A_YEAR = 31_536_000;
uint256 constant SECONDS_IN_TWO_YEARS = SECONDS_IN_A_YEAR * 2;

/**
 * @dev The address of the Hedgey Finance Token Vesting Plans on Mainnet
 */
address constant TOKEN_VESTING_PLANS = 0x2CDE9919e81b20B4B33DD562a48a84b54C48F00C;
/**
 * @dev The address of the Hedgey Finance Token Vesting Plans on Sepolia
 */
address constant TOKEN_VESTING_PLANS_155 = 0x68b6986416c7A38F630cBc644a2833A0b78b3631;

/**
 * @dev The address of the BatchPlanner contract on Mainnet
 */
address constant BATCH_PLANNER = 0x3466EB008EDD8d5052446293D1a7D212cb65C646;
/**
 * @dev The address of the BatchPlanner contract on Sepolia
 */
address constant BATCH_PLANNER_155 = 0xd8B085f666299E52f24e637aB1076ba5C2c38045;

/**
 * @dev The address of the Karpatkey Treasury Safe on Mainnet
 */
address constant KARPATKEY_TREASURY_SAFE = 0x58e6c7ab55Aa9012eAccA16d1ED4c15795669E1C;

/**
 * @dev The address of the GnosisDAO Treasury Safe on Mainnet
 */
address constant GNOSIS_DAO_TREASURY_SAFE = 0x849D52316331967b6fF1198e5E32A0eB168D039d;

/**
 * @dev The address of the Safe Create Call on Mainnet and Sepolia.
 */
address constant SAFE_CREATE_CALL = 0x7cbB62EaA69F79e6873cD1ecB2392971036cFAa4;
/**
 * @dev Safe Proxy Factory
 */
address constant SAFE_PROXY_FACTORY = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;

/**
 * @dev Interface for the Safe Create Call
 */
interface ISafeCreateCall {
  function performCreate(uint256 value, bytes memory deploymentData) external returns (address newContract);
}

/**
 * @title IBatchPlanner
 * @author karpatkey
 * @notice Interface for the BatchPlanner contract
 */
interface IBatchPlanner {
  struct Plan {
    address recipient;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
  }

  struct AllocationData {
    address recipient;
    uint256 amount;
    uint256 start;
    bool cliffBool;
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

interface ITokenVestingPlans {
  function redeemPlans(
    uint256[] memory planIds
  ) external;

  function plans(
    uint256 planId
  ) external view returns (address, uint256, uint256, uint256, uint256, uint256, address, bool);
}

/**
 * @title ISafeProxyFactory
 * @author Karpatkey
 * @notice Interface for the Safe Proxy Factory
 */
interface ISafeProxyFactory {
  function createProxyWithNonce(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce
  ) external returns (address proxy);
}
