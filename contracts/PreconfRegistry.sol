// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PreconfRegistry
/// @notice Tracks which addresses have opted‑in to act as *preconfer*
///         (a.k.a. blob proposer) and enforces collateral.
///         The collateral can later be slashed if they break pre‑confirmations.
contract PreconfRegistry {
    /*//////////////////////////////////////////////////////////////
                                PARAMS
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable minCollateral;   // e.g. 1 ETH
    address public immutable raidTreasury;    // slashed collateral receiver

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(address => uint256) public collateralOf;
    mapping(address => bool)    public isActivePreconfer;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Joined(address indexed preconfer, uint256 collateral);
    event Exited(address indexed preconfer);
    event Slashed(address indexed offender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(uint256 _minCollateral, address _treasury) payable {
        minCollateral = _minCollateral;
        raidTreasury  = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                         ON‑BOARDING / OFF‑BOARDING
    //////////////////////////////////////////////////////////////*/
    function join() external payable {
        require(!isActivePreconfer[msg.sender], "already‑joined");
        require(msg.value >= minCollateral, "collateral<min");
        collateralOf[msg.sender] = msg.value;
        isActivePreconfer[msg.sender] = true;
        emit Joined(msg.sender, msg.value);
    }

    function exit() external {
        require(isActivePreconfer[msg.sender], "not‑member");
        uint256 bal = collateralOf[msg.sender];
        collateralOf[msg.sender] = 0;
        isActivePreconfer[msg.sender] = false;
        (bool ok,) = payable(msg.sender).call{value: bal}("");
        require(ok, "ETH‑xfer‑fail");
        emit Exited(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             SLASHING HOOK
    //////////////////////////////////////////////////////////////*/
    function slash(address offender, uint256 amount) external {
        // In production this fn would be `onlyRaidInbox`.
        uint256 bal = collateralOf[offender];
        uint256 seize = amount > bal ? bal : amount;
        collateralOf[offender] = bal - seize;
        (bool ok,) = payable(raidTreasury).call{value: seize}("");
        require(ok, "ETH‑xfer‑fail");
        emit Slashed(offender, seize);
    }
}