const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SecureVault Security Validation", function () {
  let vault, authManager, owner, recipient;

  beforeEach(async function () {
    [owner, recipient] = await ethers.getSigners();

    // 1. Deploy AuthorizationManager with owner as the trusted signer
    const AuthManager = await ethers.getContractFactory("AuthorizationManager");
    authManager = await AuthManager.deploy(owner.address); // FIXED: Added owner.address
    const authManagerAddress = await authManager.getAddress();

    // 2. Deploy SecureVault with the manager address
    const Vault = await ethers.getContractFactory("SecureVault");
    vault = await Vault.deploy(authManagerAddress);

    // 3. Deposit 1 ETH into the vault
    await owner.sendTransaction({
      to: await vault.getAddress(),
      value: ethers.parseEther("1.0"),
    });
  });

  it("Should FAIL: Unauthorized or invalid signature", async function () {
    const amount = ethers.parseEther("0.1");
    const fakeAuthId = ethers.id("fake_id");
    const fakeSig = "0x" + "00".repeat(65); 

    await expect(
      vault.withdraw(recipient.address, amount, fakeAuthId, fakeSig)
    ).to.be.reverted;
  });

  it("Should SUCCEED: Valid EIP-712 signature allows withdrawal", async function () {
    const amount = ethers.parseEther("0.1");
    const authId = ethers.id("unique_request_1");
    const vaultAddress = await vault.getAddress();
    const managerAddress = await authManager.getAddress();
    const chainId = (await ethers.provider.getNetwork()).chainId;

    // 1. Define EIP-712 Domain (Matching your AuthorizationManager.sol)
    const domain = {
      name: "SecureVaultSystem",
      version: "1",
      chainId: chainId,
      verifyingContract: managerAddress
    };

    // 2. Define Types
    const types = {
      WithdrawalAuth: [
        { name: "vault", type: "address" },
        { name: "recipient", type: "address" },
        { name: "amount", type: "uint256" },
        { name: "authId", type: "bytes32" }
      ]
    };

    // 3. Define Values
    const value = {
      vault: vaultAddress,
      recipient: recipient.address,
      amount: amount,
      authId: authId
    };

    // 4. Sign the data using EIP-712 standard
    const signature = await owner.signTypedData(domain, types, value);

    // 5. Perform the withdrawal
    await expect(
      vault.withdraw(recipient.address, amount, authId, signature)
    ).to.changeEtherBalances(
      [vault, recipient],
      [ethers.parseEther("-0.1"), ethers.parseEther("0.1")]
    );
  });
});