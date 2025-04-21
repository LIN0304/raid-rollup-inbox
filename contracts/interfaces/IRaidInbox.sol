// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRaidInbox {
    /// @dev Emitted whenever a new unsafe head is set.
    event NewUnsafeHead(uint256 indexed publicationId, address proposer);

    /// @dev Emitted whenever a new safe head is promoted.
    event NewSafeHead(uint256 indexed publicationId, address proposer);

    /// Publish a blob and either `{replace,advance}` the current heads.
    /// @param blob                Raw calldata blob.
    /// @param slot                Beacon‑chain slot at which the blob is published.
    /// @param replaceUnsafeHead   true  -> try to *replace* the current `unsafeHead`
    ///                            false -> try to *advance*  the current `unsafeHead`
    /// @param validatorProof      ABI‑encoded proof ‑ see `ValidatorProofVerifier`
    function publish(
        bytes calldata blob,
        uint64 slot,
        bool   replaceUnsafeHead,
        bytes calldata validatorProof
    ) external returns (uint256 publicationId);

    /// View helpers
    function safeHead() external view returns (uint256);
    function unsafeHead() external view returns (uint256);
}