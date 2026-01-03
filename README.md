# Secure Vault System

A blockchain-based secure vault that utilizes **EIP-712 Typed Data Signatures** to authorize withdrawals. This system ensures that funds are only released when a trusted off-chain signer provides a valid, unique cryptographic permission.

## 🚀 System Architecture

The project consists of two primary smart contracts:
1.  **AuthorizationManager**: Handles the cryptographic verification of signatures and prevents "replay attacks" by tracking unique `authId`s.
2.  **SecureVault**: Holds the ETH assets and interacts with the Manager to validate requests before releasing funds.

```mermaid
graph TB
    subgraph "Off-Chain"
        A[Trusted Signer] -->|Signs EIP-712 Message| B[Authorization Request]
    end
    
    subgraph "On-Chain Smart Contracts"
        C[SecureVault Contract]
        D[AuthorizationManager Contract]
        E[(ETH Assets)]
        F[(Used Auth IDs)]
    end
    
    subgraph "User"
        G[Recipient] -->|Submits Request| C
    end
    
    B -->|authId, amount, signature| C
    C -->|Verify Authorization| D
    D -->|Check Signature| D
    D -->|Check Replay| F
    F -->|Not Used| D
    D -->|Valid| C
    C -->|Transfer ETH| G
    E -->|Holds Funds| C
    D -->|Mark Used| F
    
    style A fill:#4CAF50
    style C fill:#2196F3
    style D fill:#FF9800
    style G fill:#9C27B0
```

---

## 🛠 Features

* **Cryptographic Security**: Uses EIP-712 standard for human-readable, secure signing.
* **Reentrancy Protection**: Uses OpenZeppelin’s `ReentrancyGuard` to prevent exploit attempts during withdrawals.
* **Replay Protection**: Each authorization is unique and can only be consumed once.
* **Dockerized Environment**: Fully containerized Hardhat environment for consistent deployment.

### Withdrawal Flow

```mermaid
sequenceDiagram
    participant TS as Trusted Signer
    participant R as Recipient
    participant SV as SecureVault
    participant AM as AuthorizationManager
    participant DB as Auth ID Database

    Note over TS: Off-Chain Process
    TS->>TS: Generate unique authId
    TS->>TS: Create EIP-712 typed data
    TS->>TS: Sign message with private key
    
    Note over R,SV: On-Chain Transaction
    R->>SV: requestWithdrawal(authId, amount, signature)
    activate SV
    
    SV->>AM: verifyAndConsume(authId, amount, recipient, signature)
    activate AM
    
    AM->>AM: Recover signer from signature
    AM->>AM: Verify signer == trustedSigner
    
    AM->>DB: Check if authId already used
    DB-->>AM: Not used ✓
    
    AM->>DB: Mark authId as used
    AM-->>SV: Authorization valid ✓
    deactivate AM
    
    SV->>R: Transfer ETH
    SV-->>R: Withdrawal successful ✓
    deactivate SV
```

---

## 📋 Prerequisites

* **Docker** and **Docker Compose**
* **Node.js** (Optional, for local development)

---

## ⚙️ Setup and Deployment

### 1. Start the Environment
Run the following command to start the local blockchain and deploy the contracts automatically:
```powershell
docker-compose up -d
2. Verify Deployment
To see the deployed contract addresses:

PowerShell

cat deployed_addresses.json
🧪 Local Validation (System Integration)
We use automated tests to verify the security of the vault. The tests cover:

Unauthorized Access: Ensuring that requests with invalid signatures are reverted.

Authorized Withdrawal: Ensuring that a valid EIP-712 signature from the trusted signer successfully releases funds.

Replay Attack Prevention: Ensuring that a unique authId cannot be used twice.

To run the tests:

PowerShell

docker-compose exec vault-system npx hardhat test tests/system.spec.js
Expected Output:

Plaintext

SecureVault Security Validation
  ✔ Should FAIL: Unauthorized or invalid signature
  ✔ Should SUCCEED: Valid EIP-712 signature allows withdrawal
📂 Project Structure

```mermaid
graph TD
    A[Vault System] --> B[/contracts/]
    A --> C[/tests/]
    A --> D[/docker/]
    A --> E[/scripts/]
    A --> F[docker-compose.yml]
    A --> G[hardhat.config.js]
    A --> H[package.json]
    A --> I[deployed_addresses.json]
    
    B --> B1[AuthorizationManager.sol]
    B --> B2[SecureVault.sol]
    
    C --> C1[system.spec.js]
    
    D --> D1[Dockerfile]
    D --> D2[entrypoint.sh]
    
    E --> E1[deploy.js]
    
    style A fill:#2196F3,color:#fff
    style B fill:#4CAF50,color:#fff
    style C fill:#FF9800,color:#fff
    style D fill:#9C27B0,color:#fff
    style E fill:#F44336,color:#fff
```

**Key Components:**
- `/contracts`: Solidity smart contracts (AuthorizationManager, SecureVault)
- `/tests`: System specification and integration tests (system.spec.js)
- `/docker`: Dockerfile and environment entrypoint scripts
- `/scripts`: Deployment scripts
- `docker-compose.yml`: Infrastructure configuration
- `deployed_addresses.json`: Tracking file for contract instances

🔐 Security Note
The trustedSigner is set during the deployment of the AuthorizationManager. Ensure the private key of this signer is never exposed in a production environment.


---

### Final Check
1.  Save the **README.md**.
2.  Double-check that `tests/system.spec.js` is the only file in your `tests` folder.
3.  Run the test command one last time to be 100% sure:
    `docker-compose exec vault-system npx hardhat test tests/system.spec.js`