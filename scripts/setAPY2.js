const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Setting APY with account:", deployer.address);

  const contractAddress = "0xAeB5B8E600274CD3A22F7EbFcDae0Ee45B7f4dc7"; // Proxy NexCasa
  const rewardToken = "0xF30FFbeFBfEdc5a60A50FA31e9A473EB75e3e629"; // alamat token yang didukung
  const apyValue = 250; // contoh APY = 12%

  const contract = await ethers.getContractAt("NexCasa", contractAddress);

  const tx = await contract.setAPY(rewardToken, apyValue);
  await tx.wait();

  console.log(`✅ APY untuk token ${rewardToken} berhasil di-set ke ${apyValue}%`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
