const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const NexCasa = await ethers.getContractFactory("NexCasaV2");

  // kirim deployer.address ke initialize(owner_)
  const nexCasa = await upgrades.deployProxy(
    NexCasa,
    [deployer.address],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  await nexCasa.waitForDeployment();
  console.log("NexCasa deployed to:", await nexCasa.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
