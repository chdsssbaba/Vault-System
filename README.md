# 🔐 Secure Vault System

A blockchain-based secure vault that utilizes **EIP-712 Typed Data Signatures** to authorize withdrawals.
Funds are released **only** when a trusted off-chain signer provides a valid, unique cryptographic authorization.

---

## 🚀 System Architecture

The system consists of two core smart contracts:

1. **AuthorizationManager**

   * Verifies EIP-712 signatures
   * Confirms the trusted signer
   * Prevents replay attacks using unique `authId`s

2. **SecureVault**

   * Custodies ETH
   * Delegates authorization checks
   * Releases funds only after verification

```mermaid
graph TB
    subgraph "Off-Chain"
        A["Trusted Signer"] -->|"Signs EIP-712 Message"| B["Authorization Request"]
    end

    subgraph "On-Chain Smart Contracts"
        C["SecureVault Contract"]
        D["AuthorizationManager Contract"]
        E["ETH Assets"]
        F["Used Auth IDs"]
    end

    subgraph "User"
        G["Recipient"] -->|"Submits Request"| C
    end

    B -->|"authId, amount, signature"| C
    C -->|"Verify Authorization"| D
    D -->|"Recover & Validate Signer"| D
    D -->|"Check Replay"| F
    F -->|"Not Used"| D
    D -->|"Valid"| C
    C -->|"Transfer ETH"| G
    E -->|"Holds Funds"| C
    D -->|"Mark Used"| F
```

---

## 🛠 Features

* **EIP-712 Cryptographic Security**
  Human-readable, domain-separated structured data signing.

* **Replay Protection**
  Each authorization can be consumed **once and only once**.

* **Reentrancy Protection**
  Uses OpenZeppelin’s `ReentrancyGuard`.

* **Separation of Concerns**
  Authorization logic is isolated from asset custody.

* **Dockerized Environment**
  Reproducible Hardhat development and testing setup.

---

## 🔄 Withdrawal Flow

```mermaid
sequenceDiagram
    participant TS as Trusted Signer
    participant R as Recipient
    participant SV as SecureVault
    participant AM as AuthorizationManager
    participant DB as Used Auth IDs

    Note over TS: Off-Chain Authorization
    TS->>TS: Generate unique authId
    TS->>TS: Create EIP-712 typed data
    TS->>TS: Sign message

    Note over R,SV: On-Chain Execution
    R->>SV: requestWithdrawal(authId, amount, signature)
    SV->>AM: verifyAndConsume(authId, amount, recipient, signature)

    AM->>AM: Recover signer
    AM->>AM: Validate trusted signer
    AM->>DB: Check authId unused
    DB-->>AM: OK
    AM->>DB: Mark authId as used

    AM-->>SV: Authorization valid
    SV->>R: Transfer ETH
```

---

## 📋 Prerequisites

* **Docker**
* **Docker Compose**
* **Node.js** *(optional for local development)*

---

## ⚙️ Setup & Deployment

### 1️⃣ Start the Environment

```bash
docker-compose up -d
```

This starts a local blockchain and deploys the contracts automatically.

---

### 2️⃣ Verify Deployment

```bash
cat deployed_addresses.json
```

---

## 🧪 Local Validation (System Integration Tests)

Automated tests verify:

* ❌ **Unauthorized Access**
  Invalid or forged signatures revert.

* ✅ **Authorized Withdrawal**
  Valid EIP-712 signatures release ETH.

* 🔁 **Replay Attack Prevention**
  The same `authId` cannot be reused.

### Run Tests

```bash
docker-compose exec vault-system npx hardhat test tests/system.spec.js
```

### Expected Output

```text
SecureVault Security Validation
  ✔ Should FAIL: Unauthorized or invalid signature
  ✔ Should SUCCEED: Valid EIP-712 signature allows withdrawal
  ✔ Should FAIL: Replay attack using same authId
```

---

## 📂 Project Structure

```mermaid
graph TD
    A["Vault System"]
    A --> B["/contracts"]
    A --> C["/tests"]
    A --> D["/docker"]
    A --> E["/scripts"]
    A --> F["docker-compose.yml"]
    A --> G["hardhat.config.js"]
    A --> H["package.json"]
    A --> I["deployed_addresses.json"]

    B --> B1["AuthorizationManager.sol"]
    B --> B2["SecureVault.sol"]
    C --> C1["system.spec.js"]
    D --> D1["Dockerfile"]
    D --> D2["entrypoint.sh"]
    E --> E1["deploy.js"]
```

---

## 🔐 Security Notes

* `trustedSigner` is set **during deployment** of `AuthorizationManager`
* Never expose the trusted signer’s private key
* Rotate the signer by redeploying if compromised
* Assumes secure off-chain key management

---

## ✅ Final Checklist

1. Save this file as **`README.md`**
2. Ensure `tests/system.spec.js` is the **only test file**
3. Run the final verification:

```bash
docker-compose exec vault-system npx hardhat test tests/system.spec.js
```

---
