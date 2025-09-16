const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Setting reward token with account:", deployer.address);

  // Proxy address NexCasa
  const contractAddress = "0xAeB5B8E600274CD3A22F7EbFcDae0Ee45B7f4dc7";

  // 👉 Ganti dengan token ERC20 yang mau dipakai sebagai reward
  const rewardToken = "0xF30FFbeFBfEdc5a60A50FA31e9A473EB75e3e629"; 

  const contract = await ethers.getContractAt("NexCasaV2", contractAddress);

  const tx = await contract.setRewardToken(rewardToken);
  await tx.wait();

  console.log(`✅ Reward token berhasil di-set ke ${rewardToken}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
