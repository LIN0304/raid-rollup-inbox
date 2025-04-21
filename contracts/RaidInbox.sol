// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IRaidInbox }          from "./interfaces/IRaidInbox.sol";
import { IBeaconRoots }        from "./interfaces/IBeaconRoots.sol";
import { PublicationFeed }     from "./PublicationFeed.sol";
import { PreconfRegistry }     from "./PreconfRegistry.sol";
import { ValidatorProofVerifier as V } from "./validator/ValidatorProofVerifier.sol";

/// @title RaidInbox
/// @notice Core contract implementing the unsafeHead / safeHead state‑machine
///         described in the RAID spec.
contract RaidInbox is IRaidInbox {
    using V for V.Proof;

    /*//////////////////////////////////////////////////////////////
                                PARAMS
    //////////////////////////////////////////////////////////////*/
    PublicationFeed  public immutable feed;
    PreconfRegistry  public immutable registry;
    IBeaconRoots     public immutable beacon;   // EIP‑4788 ring‑buffer

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public safeHead;                   // last canonical publication
    uint256 public unsafeHead;                 // candidate waiting for confirmation

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _feed,
        address _registry,
        address _beaconRoots
    ) {
        feed    = PublicationFeed(_feed);
        registry = PreconfRegistry(_registry);
        beacon   = IBeaconRoots(_beaconRoots);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL PUBLISH API
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IRaidInbox
    function publish(
        bytes calldata blob,
        uint64 slot,
        bool   replaceUnsafeHead,
        bytes calldata validatorProof
    )
        external
        override
        returns (uint256 pid)
    {
        /// ----------------------------------------------------------------
        /// 0. Preconditions
        /// ----------------------------------------------------------------
        require(registry.isActivePreconfer(msg.sender), "not‑preconfer");
        pid = feed.publish(blob, slot);

        /// ----------------------------------------------------------------
        /// 1. No previous unsafe head → trivial set
        /// ----------------------------------------------------------------
        if (unsafeHead == 0) {
            require(replaceUnsafeHead, "must‑replace‑genesis");
            unsafeHead = pid;
            emit NewUnsafeHead(pid, msg.sender);
            return pid;
        }

        /// ----------------------------------------------------------------
        /// 2. Fetch previous publication & build proof struct
        /// ----------------------------------------------------------------
        PublicationFeed.Publication memory prev = feed.publications(unsafeHead);
        V.Proof memory proof = abi.decode(validatorProof, (V.Proof));

        bool ok = proof.verify(beacon);
        require(ok, "invalid‑proof");

        /// ----------------------------------------------------------------
        /// 3. Replace or Advance
        /// ----------------------------------------------------------------
        if (replaceUnsafeHead) {
            // Proof must show *different* proposer than prev.publisher
            require(proof.proposerAddr != prev.publisher,
                    "cannot‑replace‑same‑proposer");
            unsafeHead = pid;
            emit NewUnsafeHead(pid, msg.sender);
        } else {
            // Proof must show *same* proposer as prev.publisher
            require(proof.proposerAddr == prev.publisher,
                    "cannot‑advance‑different‑proposer");
            // Promote to safe
            safeHead = unsafeHead;
            emit NewSafeHead(safeHead, prev.publisher);
            // Shift new pid into unsafe
            unsafeHead = pid;
            emit NewUnsafeHead(pid, msg.sender);
        }
    }
}