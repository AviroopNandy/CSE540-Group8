import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
  const signers = await ethers.getSigners();
  const deployer  = signers[0]; // Admin
  const farmer    = signers[1];
  const processor = signers[2];
  const logistics = signers[3];
  const retailer  = signers[4];
  const regulator = signers[5];

  console.log("Deploying with Admin account:", deployer.address);

  // Step 1: Deploy ProvenanceRegistry
  const ProvenanceRegistry = await ethers.getContractFactory("ProvenanceRegistry");
  const registry = await ProvenanceRegistry.deploy();
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("ProvenanceRegistry deployed to:", registryAddress);

  // Step 2: Deploy AlertRecallManager, linked to ProvenanceRegistry
  const AlertRecallManager = await ethers.getContractFactory("AlertRecallManager");
  const recall = await AlertRecallManager.deploy(registryAddress);
  await recall.waitForDeployment();
  const recallAddress = await recall.getAddress();
  console.log("AlertRecallManager deployed to:", recallAddress);

  // Step 3: Link AlertRecallManager back into ProvenanceRegistry
  await (await registry.setRecallManagerAddress(recallAddress)).wait();
  console.log("Contracts linked.");

  // Step 4: Assign roles to demo accounts
  // Role enum: 0=None,1=Admin,2=Farmer,3=Processor,4=Logistics,5=Retailer,6=Regulator
  await (await registry.assignRole(farmer.address,    2)).wait();
  await (await registry.assignRole(processor.address, 3)).wait();
  await (await registry.assignRole(logistics.address, 4)).wait();
  await (await registry.assignRole(retailer.address,  5)).wait();
  await (await registry.assignRole(regulator.address, 6)).wait();
  console.log("Roles assigned to demo accounts.");

  console.log("\n========================================");
  console.log("Update these in frontend/index.html:");
  console.log("PROVENANCE_REGISTRY_ADDRESS =", registryAddress);
  console.log("ALERT_RECALL_MANAGER_ADDRESS =", recallAddress);
  console.log("\nDemo accounts (from hardhat node):");
  console.log("Admin     (account 0):", deployer.address);
  console.log("Farmer    (account 1):", farmer.address);
  console.log("Processor (account 2):", processor.address);
  console.log("Logistics (account 3):", logistics.address);
  console.log("Retailer  (account 4):", retailer.address);
  console.log("Regulator (account 5):", regulator.address);
  console.log("========================================");
}

main().then(() => process.exit(0)).catch((err) => { console.error(err); process.exit(1); });