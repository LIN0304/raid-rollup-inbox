// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title EIP‑4788 Beacon Root Ring‑Buffer Interface
/// @author Raid
/// @notice ERC‑5564 standard interface for the on‑chain beacon‑root buffer at
///         0x000000000000000000000000000000000000Beacon (post‑Dencun main‑net)
interface IBeaconRoots {
    /// @return root The beacon block root at a given `slot`
    function getBeaconRoot(uint64 slot) external view returns (bytes32 root);
}