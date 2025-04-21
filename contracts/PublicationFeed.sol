// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PublicationFeed
/// @notice Thin blob registry that mints incremental IDs for off‑chain blobs.
///         This is intentionally generic so that the same feed can be re‑used
///         by multiple rollups.
contract PublicationFeed {
    struct Publication {
        address publisher;
        bytes32 blobHash;   // keccak256(blob)
        uint64  slot;       // beacon‑chain slot at publication
        uint256 timestamp;  // L1 block.timestamp
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public nextId = 1;
    mapping(uint256 => Publication) public publications;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Published(uint256 indexed id, address indexed publisher, bytes32 blobHash);

    /*//////////////////////////////////////////////////////////////
                             PUBLISH LOGIC
    //////////////////////////////////////////////////////////////*/
    function publish(bytes calldata blob, uint64 slot) external returns (uint256 id) {
        id = nextId++;
        publications[id] = Publication({
            publisher: msg.sender,
            blobHash:  keccak256(blob),
            slot:      slot,
            timestamp: block.timestamp
        });
        emit Published(id, msg.sender, keccak256(blob));
    }
}