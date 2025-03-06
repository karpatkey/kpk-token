import { config as load } from "dotenv";
import {
  Address,
  Chain,
  createPublicClient,
  createWalletClient,
  encodeFunctionData,
  getContract,
  http,
  parseEther,
  zeroAddress,
} from "viem";
import { PrivateKeyAccount, privateKeyToAccount } from "viem/accounts";
import { mainnet, sepolia } from "viem/chains";
import { writeFileSync } from "node:fs";

load();

// Import contract ABIs
import TimelockController_Artifact from "../out/TimelockController.sol/TimelockController.json" with {
  type: "json",
};
import KpkToken_Artifact from "../out/KpkToken.sol/KpkToken.json" with {
  type: "json",
};
import TransparentUpgradeableProxy_Artifact from "../out/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json" with {
  type: "json",
};
import ProxyAdmin_Artifact from "../out/ProxyAdmin.sol/ProxyAdmin.json" with {
  type: "json",
};
import KpkGovernor_Artifact from "../out/KpkGovernor.sol/KpkGovernor.json" with {
  type: "json",
};
import {
  batchPlannerAbi,
  kpkGovernorAbi,
  kpkTokenAbi,
  proxyAdminAbi,
  timelockControllerAbi,
  transparentUpgradeableProxyAbi,
} from "./abis.ts";

// Constants from KpkDeployerLib.sol
const SECONDS_IN_A_YEAR = 31_536_000n;
const SECONDS_IN_TWO_YEARS = SECONDS_IN_A_YEAR * 2n;
const TOKEN_VESTING_PLANS = "0x2CDE9919e81b20B4B33DD562a48a84b54C48F00C";
const TOKEN_VESTING_PLANS_SEPOLIA =
  "0x68b6986416c7A38F630cBc644a2833A0b78b3631";
const BATCH_PLANNER = "0x3466EB008EDD8d5052446293D1a7D212cb65C646";
const BATCH_PLANNER_SEPOLIA = "0xd8B085f666299E52f24e637aB1076ba5C2c38045";
const KPK_TREASURY_SAFE = "0x58e6c7ab55Aa9012eAccA16d1ED4c15795669E1C";
const GNOSIS_DAO_TREASURY_SAFE = "0x849D52316331967b6fF1198e5E32A0eB168D039d";

// Allocated token amounts
const GNOSIS_DAO_ALLOCATION_1 = parseEther("25000000");
const GNOSIS_DAO_ALLOCATION_2 = parseEther("50000000");

// Types
interface Plan {
  recipient: Address;
  amount: bigint;
  start: bigint;
  cliff: bigint;
  rate: bigint;
}

interface DeploymentResult {
  network: string;
  chainId: number;
  timelockController: string;
  kpkToken: string;
  kpkTokenProxyAdmin: string;
  kpkGovernor: string;
  kpkGovernorProxyAdmin: string;
  timestamp: number;
}

const confirmations = 3 as const;

// Main deployment function
async function deploy(
  account: PrivateKeyAccount,
  chain: Chain,
  rpcURL: string,
  deployerAddress: Address,
  vestingPlansRecipientAddress: Address,
  finalHolderOfKpkAddress: Address,
): Promise<DeploymentResult> {
  const tokenVestingPlansAddress = chain.id === sepolia.id
    ? TOKEN_VESTING_PLANS_SEPOLIA
    : TOKEN_VESTING_PLANS;
  const batchPlannerAddress = chain.id === sepolia.id
    ? BATCH_PLANNER_SEPOLIA
    : BATCH_PLANNER;

  const publicClient = createPublicClient({
    chain,
    transport: http(rpcURL),
  });

  const walletClient = createWalletClient({
    account,
    chain,
    transport: http(rpcURL),
  });

  console.log("Starting deployment process...");
  console.log(`Deployer: ${deployerAddress}`);
  console.log(`Vesting Plans Recipient: ${vestingPlansRecipientAddress}`);
  console.log(`Final KPK Token Holder: ${finalHolderOfKpkAddress}`);
  console.log(`Network: ${chain.name}`);

  const chainId = await publicClient.getChainId();
  const deploymentResult: DeploymentResult = {
    network: chain.name,
    chainId,
    timelockController: "",
    kpkToken: "",
    kpkTokenProxyAdmin: "",
    kpkGovernor: "",
    kpkGovernorProxyAdmin: "",
    timestamp: Math.floor(Date.now() / 1000),
  };

  // Governance parameters
  const timelockMinDelay = 3600n * 24n; // 1 day
  const timelockProposers: Address[] = [];
  const timelockExecutors: Address[] = [zeroAddress]; // Anyone can execute

  console.log("Deploying TimelockController...");
  // Deploy TimelockController
  const timelockHash = await walletClient.deployContract({
    abi: timelockControllerAbi,
    bytecode: TimelockController_Artifact.bytecode.object as `0x${string}`,
    args: [
      BigInt(timelockMinDelay),
      timelockProposers,
      timelockExecutors,
      deployerAddress,
    ],
  });

  console.log(`TimelockController deployment transaction: ${timelockHash}`);

  // Wait for confirmations
  const timelockReceipt = await publicClient.waitForTransactionReceipt({
    hash: timelockHash,
    confirmations: 3,
  });

  const timelockControllerAddress = timelockReceipt
    .contractAddress as `0x${string}`;
  console.log(`TimelockController deployed at: ${timelockControllerAddress}`);
  deploymentResult.timelockController = timelockControllerAddress;

  // Get TimelockController contract instance
  const timelockController = getContract({
    address: timelockControllerAddress,
    abi: timelockControllerAbi,
    client: walletClient,
  });

  // Deploy KpkToken as an upgradeable proxy
  console.log("Deploying KpkToken implementation...");
  const kpkTokenImplHash = await walletClient.deployContract({
    abi: kpkTokenAbi,
    bytecode: KpkToken_Artifact.bytecode.object as `0x${string}`,
  });

  console.log(
    `KpkToken implementation deployment transaction: ${kpkTokenImplHash}`,
  );

  const kpkTokenImplReceipt = await publicClient.waitForTransactionReceipt({
    hash: kpkTokenImplHash,
    confirmations: 3,
  });

  const kpkTokenImplAddress = kpkTokenImplReceipt
    .contractAddress as `0x${string}`;
  console.log(`KpkToken implementation deployed at: ${kpkTokenImplAddress}`);

  // Deploy ProxyAdmin
  console.log("Deploying ProxyAdmin for KpkToken...");
  const kpkProxyAdminHash = await walletClient.deployContract({
    abi: proxyAdminAbi,
    bytecode: ProxyAdmin_Artifact.bytecode.object as `0x${string}`,
    args: [deployerAddress],
  });

  console.log(
    `KpkToken ProxyAdmin deployment transaction: ${kpkProxyAdminHash}`,
  );

  const kpkProxyAdminReceipt = await publicClient.waitForTransactionReceipt({
    hash: kpkProxyAdminHash,
    confirmations: 3,
  });

  const kpkProxyAdminAddress = kpkProxyAdminReceipt
    .contractAddress as `0x${string}`;
  console.log(`KpkToken ProxyAdmin deployed at: ${kpkProxyAdminAddress}`);
  deploymentResult.kpkTokenProxyAdmin = kpkProxyAdminAddress;

  // Transfer ProxyAdmin ownership to TimelockController
  const proxyAdmin = getContract({
    address: kpkProxyAdminAddress,
    abi: proxyAdminAbi,
    client: walletClient,
  });

  console.log(
    "Transferring KpkToken ProxyAdmin ownership to TimelockController...",
  );
  const transferOwnershipHash = await proxyAdmin.write.transferOwnership([
    timelockControllerAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: transferOwnershipHash,
    confirmations: 3,
  });

  console.log("ProxyAdmin ownership transferred");

  // Deploy the KpkToken proxy
  console.log("Deploying KpkToken proxy...");
  const initData = encodeFunctionData({
    abi: kpkTokenAbi,
    functionName: "initialize",
    args: [deployerAddress],
  });

  const kpkTokenProxyHash = await walletClient.deployContract({
    abi: transparentUpgradeableProxyAbi,
    bytecode: TransparentUpgradeableProxy_Artifact.bytecode
      .object as `0x${string}`,
    args: [kpkTokenImplAddress, kpkProxyAdminAddress, initData],
  });

  console.log(`KpkToken proxy deployment transaction: ${kpkTokenProxyHash}`);

  const kpkTokenProxyReceipt = await publicClient.waitForTransactionReceipt({
    hash: kpkTokenProxyHash,
    confirmations: 3,
  });

  const kpkTokenProxyAddress = kpkTokenProxyReceipt
    .contractAddress as `0x${string}`;
  console.log(`KpkToken proxy deployed at: ${kpkTokenProxyAddress}`);
  deploymentResult.kpkToken = kpkTokenProxyAddress;

  // Get KpkToken proxy contract instance
  const kpkToken = getContract({
    address: kpkTokenProxyAddress,
    abi: kpkTokenAbi,
    client: walletClient,
  });

  // Deploy KpkGovernor implementation
  console.log("Deploying KpkGovernor implementation...");
  const kpkGovernorImplHash = await walletClient.deployContract({
    abi: kpkGovernorAbi,
    bytecode: KpkGovernor_Artifact.bytecode.object as `0x${string}`,
  });

  console.log(
    `KpkGovernor implementation deployment transaction: ${kpkGovernorImplHash}`,
  );

  const kpkGovernorImplReceipt = await publicClient.waitForTransactionReceipt({
    hash: kpkGovernorImplHash,
    confirmations: 3,
  });

  const kpkGovernorImplAddress = kpkGovernorImplReceipt
    .contractAddress as `0x${string}`;
  console.log(
    `KpkGovernor implementation deployed at: ${kpkGovernorImplAddress}`,
  );

  // Deploy ProxyAdmin for KpkGovernor
  console.log("Deploying ProxyAdmin for KpkGovernor...");
  const kpkGovernorProxyAdminHash = await walletClient.deployContract({
    abi: proxyAdminAbi,
    bytecode: ProxyAdmin_Artifact.bytecode.object as `0x${string}`,
    args: [deployerAddress],
  });

  console.log(
    `KpkGovernor ProxyAdmin deployment transaction: ${kpkGovernorProxyAdminHash}`,
  );

  const kpkGovernorProxyAdminReceipt = await publicClient
    .waitForTransactionReceipt({
      hash: kpkGovernorProxyAdminHash,
      confirmations: 3,
    });

  const kpkGovernorProxyAdminAddress = kpkGovernorProxyAdminReceipt
    .contractAddress as `0x${string}`;
  console.log(
    `KpkGovernor ProxyAdmin deployed at: ${kpkGovernorProxyAdminAddress}`,
  );
  deploymentResult.kpkGovernorProxyAdmin = kpkGovernorProxyAdminAddress;

  // Transfer KpkGovernor ProxyAdmin ownership to TimelockController
  const governorProxyAdmin = getContract({
    address: kpkGovernorProxyAdminAddress,
    abi: proxyAdminAbi,
    client: walletClient,
  });

  console.log(
    "Transferring KpkGovernor ProxyAdmin ownership to TimelockController...",
  );
  const transferGovOwnershipHash = await governorProxyAdmin.write
    .transferOwnership([timelockControllerAddress]);

  await publicClient.waitForTransactionReceipt({
    hash: transferGovOwnershipHash,
    confirmations: 3,
  });

  console.log("KpkGovernor ProxyAdmin ownership transferred");

  // Deploy the KpkGovernor proxy
  console.log("Deploying KpkGovernor proxy...");
  const govInitData = encodeFunctionData({
    abi: kpkGovernorAbi,
    functionName: "initialize",
    args: [kpkTokenProxyAddress, timelockControllerAddress],
  });

  const kpkGovernorProxyHash = await walletClient.deployContract({
    abi: transparentUpgradeableProxyAbi,
    bytecode: TransparentUpgradeableProxy_Artifact.bytecode
      .object as `0x${string}`,
    args: [kpkGovernorImplAddress, kpkGovernorProxyAdminAddress, govInitData],
  });

  console.log(
    `KpkGovernor proxy deployment transaction: ${kpkGovernorProxyHash}`,
  );

  const kpkGovernorProxyReceipt = await publicClient.waitForTransactionReceipt({
    hash: kpkGovernorProxyHash,
    confirmations: 3,
  });

  const kpkGovernorProxyAddress = kpkGovernorProxyReceipt
    .contractAddress as `0x${string}`;
  console.log(`KpkGovernor proxy deployed at: ${kpkGovernorProxyAddress}`);
  deploymentResult.kpkGovernor = kpkGovernorProxyAddress;

  // Grant roles to KpkGovernor
  console.log("Setting up roles in TimelockController...");

  // Grant PROPOSER_ROLE to Governor
  const proposerRole = await timelockController.read.PROPOSER_ROLE();
  const grantProposerHash = await timelockController.write.grantRole([
    proposerRole,
    kpkGovernorProxyAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: grantProposerHash,
    confirmations: 3,
  });

  console.log(
    `Granted PROPOSER_ROLE to Governor at ${kpkGovernorProxyAddress}`,
  );

  // Grant CANCELLER_ROLE to Governor
  const cancellerRole = await timelockController.read.CANCELLER_ROLE();
  const grantCancellerHash = await timelockController.write.grantRole([
    cancellerRole,
    kpkGovernorProxyAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: grantCancellerHash,
    confirmations,
  });

  console.log(
    `Granted CANCELLER_ROLE to Governor at ${kpkGovernorProxyAddress}`,
  );

  // Grant DEFAULT_ADMIN_ROLE to finalHolderOfKpk
  const adminRole = await timelockController.read.DEFAULT_ADMIN_ROLE();
  const grantAdminHash = await timelockController.write.grantRole([
    adminRole,
    finalHolderOfKpkAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: grantAdminHash,
    confirmations,
  });

  console.log(`Granted DEFAULT_ADMIN_ROLE to ${finalHolderOfKpkAddress}`);

  // Renounce DEFAULT_ADMIN_ROLE from deployer
  const renounceAdminHash = await timelockController.write.renounceRole([
    adminRole,
    deployerAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: renounceAdminHash,
    confirmations,
  });

  console.log(`Renounced DEFAULT_ADMIN_ROLE from ${deployerAddress}`);

  // Setup vesting plans
  console.log("Setting up vesting plans...");

  const plans: Plan[] = [
    {
      recipient: vestingPlansRecipientAddress,
      amount: GNOSIS_DAO_ALLOCATION_1,
      start: 1_642_075_200n, // The date GIP-20 was approved in Snapshot, i.e. January 13th, 2022, 12:00 UTC
      cliff: 1_642_075_200n, // No cliff, i.e. cliffDate = startDate
      rate: GNOSIS_DAO_ALLOCATION_1 / BigInt(SECONDS_IN_TWO_YEARS),
    },
    {
      recipient: vestingPlansRecipientAddress,
      amount: GNOSIS_DAO_ALLOCATION_2,
      start: 1_740_706_140n + SECONDS_IN_A_YEAR, // The date GIP-20 was approved in Snapshot + 1 year, i.e. February 28th, 2025, 01:29 UTC + 1 year
      cliff: 1_740_706_140n + SECONDS_IN_A_YEAR, // No cliff, i.e. cliffDate = startDate
      rate: GNOSIS_DAO_ALLOCATION_2 / BigInt(SECONDS_IN_TWO_YEARS),
    },
  ];

  console.log(`Using TokenVestingPlans at ${tokenVestingPlansAddress}`);
  console.log(`Using BatchPlanner at ${batchPlannerAddress}`);

  // Allow vesting contracts to transfer tokens
  console.log("Setting transfer allowlists...");
  const allowlistVestingHash = await kpkToken.write.transferAllowlist([
    tokenVestingPlansAddress,
    true,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: allowlistVestingHash,
    confirmations,
  });

  console.log(`Added ${tokenVestingPlansAddress} to transfer allowlist`);

  const allowlistPlannerHash = await kpkToken.write.transferAllowlist([
    batchPlannerAddress,
    true,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: allowlistPlannerHash,
    confirmations,
  });

  console.log(`Added ${batchPlannerAddress} to transfer allowlist`);

  // Approve BatchPlanner to spend tokens
  console.log("Approving BatchPlanner to spend tokens...");
  const totalAllocation = GNOSIS_DAO_ALLOCATION_1 + GNOSIS_DAO_ALLOCATION_2;
  const approveHash = await kpkToken.write.approve([
    batchPlannerAddress,
    totalAllocation,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: approveHash,
    confirmations,
  });

  console.log(`Approved BatchPlanner to spend ${totalAllocation} tokens`);

  // Create vesting plans
  console.log("Creating vesting plans via BatchPlanner...");
  const batchPlanner = getContract({
    address: batchPlannerAddress,
    abi: batchPlannerAbi,
    client: walletClient,
  });

  const createPlansHash = await batchPlanner.write.batchVestingPlans([
    tokenVestingPlansAddress,
    kpkTokenProxyAddress,
    totalAllocation,
    plans,
    1n, // period
    finalHolderOfKpkAddress, // vestingAdmin
    true, // adminTransferOBO
    4, // mintType
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: createPlansHash,
    confirmations: 3,
  });

  console.log("Vesting plans created successfully");

  // Transfer remaining tokens to finalHolderOfKpk
  console.log("Transferring remaining tokens to final holder...");
  const balance = await kpkToken.read.balanceOf([deployerAddress]);

  if (balance > 0n) {
    const transferHash = await kpkToken.write.transfer([
      finalHolderOfKpkAddress,
      balance,
    ]);

    await publicClient.waitForTransactionReceipt({
      hash: transferHash,
      confirmations: 3,
    });

    console.log(`Transferred ${balance} tokens to ${finalHolderOfKpkAddress}`);
  } else {
    console.log("No tokens to transfer");
  }

  // Transfer token ownership
  console.log("Transferring token ownership to final holder...");
  const transferOwnerHash = await kpkToken.write.transferOwnership([
    finalHolderOfKpkAddress,
  ]);

  await publicClient.waitForTransactionReceipt({
    hash: transferOwnerHash,
    confirmations: 3,
  });

  console.log(`Transferred KpkToken ownership to ${finalHolderOfKpkAddress}`);

  console.log("Deployment completed successfully!");
  return deploymentResult;
}

async function main() {
  const args = process.argv;
  const network = args[2]?.toLowerCase();
  const privateKey = process.env.PRIVATE_KEY;
  const allowedNetworks = ["sepolia", "mainnet"];

  if (!allowedNetworks.includes(network)) {
    console.log("Please specify a network: sepolia or mainnet");
    console.log(
      "Usage: node --loader ts-node/esm script/deploy.ts [network]",
    );
    process.exit(1);
  }

  const chain = network === "sepolia" ? sepolia : mainnet;

  if (!privateKey) {
    throw new Error("PRIVATE_KEY environment variable is required");
  }

  const rpcUrl = process.env[
    network === "sepolia" ? "SEPOLIA_RPC" : "MAINNET_RPC"
  ];
  if (!rpcUrl) {
    throw new Error(
      network === "sepolia"
        ? "SEPOLIA_RPC environment variable is required"
        : "MAINNET_RPC environment variable is required",
    );
  }

  const account = privateKeyToAccount(privateKey as `0x${string}`);

  console.log({
    privateKey,
    network,
    rpcUrl,
  });

  const deployerAddress = account.address;
  const vestingPlansRecipientAddress = GNOSIS_DAO_TREASURY_SAFE;
  const finalHolderOfKpkAddress = KPK_TREASURY_SAFE;

  console.log(`Deploying to ${chain.name}...`);

  const result = await deploy(
    account,
    chain,
    rpcUrl,
    deployerAddress,
    vestingPlansRecipientAddress,
    finalHolderOfKpkAddress,
  );

  // Write deployment results to a JSON file
  const filename = `deployment-${chain.name}-${result.timestamp}.json`;
  writeFileSync(filename, JSON.stringify(result, null, 2));
  console.log(`Deployment information saved to ${filename}`);
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exit(1);
});
