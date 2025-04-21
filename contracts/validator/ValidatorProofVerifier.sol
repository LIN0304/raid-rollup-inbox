// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IBeaconRoots } from "../interfaces/IBeaconRoots.sol";
import { MerkleProofLib } from "../utils/MerkleProofLib.sol";

/// @title ValidatorProofVerifier
/// @dev For the PoC we *optimistically* verify that `proposerAddr`
///      exists at path `proposerIndex` in the beacon‑state validator tree.
///      Production deployments SHOULD swap this contract with a full‑blown
///      SSZ‑Merkle proof verifier (e.g. `light‑client‑proofs`).
library ValidatorProofVerifier {
    struct Proof {
        uint64  slot;          // Beacon‑chain slot for `unsafeHead`
        uint64  proposerIndex; // Validator index of the slot‑leader
        address proposerAddr;  // Execution‑layer address claimed to have the slot
        bytes32[] branch;      // SSZ / Merkle multi‑proof
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VERIFICATION
    //////////////////////////////////////////////////////////////*/
    function verify(
        IBeaconRoots beacon,
        Proof calldata proof
    ) internal view returns (bool) {
        // 1. Fetch beacon root committed via EIP‑4788
        bytes32 root = beacon.getBeaconRoot(proof.slot);
        if (root == bytes32(0)) return false;

        // 2. Build leaf (we hash the 20‑byte address into 32 bytes)
        bytes32 leaf = keccak256(abi.encodePacked(bytes12(0), proof.proposerAddr));

        // 3. Check Merkle inclusion
        bool ok = MerkleProofLib.verifyProof(
            leaf,
            proof.branch,
            root
        );

        return ok;
    }
}