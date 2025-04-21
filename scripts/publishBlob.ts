import { ethers } from "hardhat";
import { readFileSync } from "fs";

const INBOX = "0xYourInboxAddress";

async function main() {
  const [me] = await ethers.getSigners();
  const inbox = await ethers.getContractAt("RaidInbox", INBOX);

  const rawBlob = readFileSync("./blob.json");      // arbitrary payload
  const slot    = 123456n;                          // beacon slot height
  const replace = true;

  // Dummy proof for local dev
  const proof = ethers.utils.defaultAbiCoder.encode(
    ["tuple(uint64,uint64,address,bytes32[])"],
    [
      [
        slot,
        0n,                     // proposerIndex
        me.address,
        []                      // branch
      ],
    ]
  );

  const tx = await inbox.publish(rawBlob, slot, replace, proof);
  console.log("publish tx:", tx.hash);
  await tx.wait();
}

main().catch(console.error);