import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  const schoolResult = await ethers.deployContract("SchoolResult");

  await schoolResult.waitForDeployment();

  console.log(
    `${await schoolResult.getAddress()} deployed by ${owner.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
