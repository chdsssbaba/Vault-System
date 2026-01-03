// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract AuthorizationManager {
    using ECDSA for bytes32;

    // The address authorized to sign off-chain permissions
    address public immutable trustedSigner;
    
    // Track consumed authorizations to prevent replay attacks
    mapping(bytes32 => bool) public consumedAuthorizations;

    // EIP-712 Domain Separator components
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private constant AUTH_TYPEHASH = keccak256(
        "WithdrawalAuth(address vault,address recipient,uint256 amount,bytes32 authId)"
    );

    event AuthorizationConsumed(bytes32 indexed authId, address indexed recipient);

    constructor(address _trustedSigner) {
        require(_trustedSigner != address(0), "Invalid signer");
        trustedSigner = _trustedSigner;

        // Initialize EIP-712 Domain Separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SecureVaultSystem")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Validates the authorization and marks it as used.
     * Only callable by the vault (though we keep it flexible, 
     * the state change ensures it can only result in one successful withdrawal).
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes calldata signature
    ) external returns (bool) {
        // 1. Ensure authorization has not been used before
        require(!consumedAuthorizations[authId], "Authorization already consumed");

        // 2. Reconstruct the EIP-712 typed data hash
        bytes32 structHash = keccak256(
            abi.encode(AUTH_TYPEHASH, vault, recipient, amount, authId)
        );
        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        // 3. Recover signer and validate
        address signer = digest.recover(signature);
        require(signer == trustedSigner, "Invalid signature");

        // 4. Mark as consumed
        consumedAuthorizations[authId] = true;

        emit AuthorizationConsumed(authId, recipient);
        return true;
    }
}