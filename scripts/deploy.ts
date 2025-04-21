import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  // 1. Deploy auxiliary contracts
  const Feed = await ethers.getContractFactory("PublicationFeed");
  const feed = await Feed.deploy();
  await feed.deployed();

  const Registry = await ethers.getContractFactory("PreconfRegistry");
  const registry = await Registry.deploy(
    ethers.utils.parseEther("1"),           // min collateral = 1 ETH
    deployer.address                        // treasury = deployer
  );
  await registry.deployed();

  // Main‑net beacon‑root contract address post‑Dencun
  const BEACON_ROOTS = "0x000000000000000000000000000000000000Beac";
  const Inbox = await ethers.getContractFactory("RaidInbox");
  const inbox = await Inbox.deploy(feed.address, registry.address, BEACON_ROOTS);
  await inbox.deployed();

  console.log(`Feed     @ ${feed.address}`);
  console.log(`Registry @ ${registry.address}`);
  console.log(`Inbox    @ ${inbox.address}`);
}

main().catch((e) => { console.error(e); process.exit(1); });