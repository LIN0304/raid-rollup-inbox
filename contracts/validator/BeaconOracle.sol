// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @notice Minimal wrapper to future‑proof the address change of the beacon‑root contract
///         without redeploying the entire Raid stack.
contract BeaconOracle {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable beaconRoots; // 0x000…beac02 on main‑net

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _beaconRoots) {
        require(_beaconRoots != address(0), "zero‑addr");
        beaconRoots = _beaconRoots;
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/
    function rootAt(uint64 slot) external view returns (bytes32) {
        return IBeaconRoots(beaconRoots).getBeaconRoot(slot);
    }
}

interface IBeaconRoots {
    function getBeaconRoot(uint64 slot) external view returns (bytes32);
}