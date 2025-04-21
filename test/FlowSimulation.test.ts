import { ethers } from "hardhat";
import { expect } from "chai";

describe("Raid Flow Simulation", () => {
  let feed: any, registry: any, inbox: any, alice: any, bob: any;

  beforeEach(async () => {
    [alice, bob] = await ethers.getSigners();

    const Feed = await ethers.getContractFactory("PublicationFeed");
    feed = await Feed.deploy();
    await feed.deployed();

    const Registry = await ethers.getContractFactory("PreconfRegistry");
    registry = await Registry.deploy(0, alice.address);
    await registry.deployed();

    const BEACON = "0x000000000000000000000000000000000000Beac";
    const Inbox = await ethers.getContractFactory("RaidInbox");
    inbox = await Inbox.deploy(feed.address, registry.address, BEACON);
    await inbox.deployed();

    // pre‑conference join
    await registry.connect(alice).join({ value: 0 });
    await registry.connect(bob).join({ value: 0 });
  });

  it("genesis replace → advance", async () => {
    // Alice publishes B0 (replaceUnsafeHead = true)
    await inbox.connect(alice).publish("0x01", 1, true, "0x");

    // Bob tries invalid advance → should revert because proof mismatch
    await expect(
      inbox.connect(bob).publish("0x02", 2, false, "0x")
    ).to.be.reverted;

    // Alice advances herself (replaceUnsafeHead = false, dummy proof ok)
    await inbox.connect(alice).publish("0x03", 3, false, "0x");

    expect(await inbox.safeHead()).to.eq(1);
    expect(await inbox.unsafeHead()).to.eq(2);
  });
});