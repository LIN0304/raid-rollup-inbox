// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library MerkleProofLib {
    /// @notice Very small re‑implementation of OZ's `MerkleProof` to avoid full import.
    function verifyProof(
        bytes32 leaf,
        bytes32[] calldata proof,
        bytes32 root
    ) internal pure returns (bool ok) {
        bytes32 hash = leaf;
        for (uint256 i; i < proof.length; ++i) {
            bytes32 p = proof[i];
            hash = hash < p ? keccak256(abi.encodePacked(hash, p))
                            : keccak256(abi.encodePacked(p, hash));
        }
        ok = (hash == root);
    }
}