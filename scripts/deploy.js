// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const BAB = await hre.ethers.getContractFactory("BullAndBear");
  const bab = await BAB.deploy();

  await bab.deployed();

  console.log(`BAB deployed to ${lock.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
