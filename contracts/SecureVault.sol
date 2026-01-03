// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AuthorizationManager.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SecureVault is ReentrancyGuard {
    // Reference to the Authorization Manager
    AuthorizationManager public immutable authManager;

    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount, bytes32 indexed authId);

    constructor(address _authManager) {
        require(_authManager != address(0), "Invalid manager address");
        authManager = AuthorizationManager(_authManager);
    }

    /**
     * @dev Explicitly accept ETH deposits and emit event.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Validates authorization via the manager and releases funds.
     */
    function withdraw(
        address payable recipient,
        uint256 amount,
        bytes32 authId,
        bytes calldata signature
    ) external nonReentrant {
        require(address(this).balance >= amount, "Insufficient vault balance");

        // 1. Request authorization validation from the Manager
        bool isAuthorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            authId,
            signature
        );

        require(isAuthorized, "Authorization failed");

        // 2. Interaction: Transfer funds
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        // 3. Log the successful withdrawal
        emit Withdrawal(recipient, amount, authId);
    }
}