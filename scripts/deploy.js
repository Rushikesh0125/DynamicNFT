// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const BAB = await hre.ethers.getContractFactory("BullAndBear");
  const bab = await BAB.deploy(
    30,
    "0xa39434a63a52e749f02807ae27335515ba4b07f7",
    "0x2bce784e69d2Ff36c71edcB9F88358dB0DfB55b4"
  );

  await bab.deployed();

  console.log(`BAB deployed to ${bab.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
