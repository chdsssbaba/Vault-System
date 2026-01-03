const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 1. Deploy AuthorizationManager
  // We use the deployer as the trusted signer for this demo
  const AuthorizationManager = await hre.ethers.getContractFactory("AuthorizationManager");
  const authManager = await AuthorizationManager.deploy(deployer.address);
  await authManager.waitForDeployment();
  const authAddress = await authManager.getAddress();
  
  console.log("--------------------------------------------------");
  console.log("AuthorizationManager deployed to:", authAddress);

  // 2. Deploy SecureVault with the AuthorizationManager address
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(authAddress);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();

  console.log("SecureVault deployed to:", vaultAddress);
  console.log("--------------------------------------------------");
  
  // 3. Log addresses to a file for easy access by the host
  const fs = require("fs");
  const addresses = {
    network: hre.network.name,
    authorizationManager: authAddress,
    secureVault: vaultAddress,
    trustedSigner: deployer.address
  };
  fs.writeFileSync("deployed_addresses.json", JSON.stringify(addresses, null, 2));
  console.log("Addresses saved to deployed_addresses.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});