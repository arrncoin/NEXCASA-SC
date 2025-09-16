const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Allowing token with account:", deployer.address);

  // Alamat kontrak proxy NexCasa
  const contractAddress = "0xAeB5B8E600274CD3A22F7EbFcDae0Ee45B7f4dc7";

  // Token yang mau diizinkan
  const tokenAddress = "0xF30FFbeFBfEdc5a60A50FA31e9A473EB75e3e629";

  const contract = await ethers.getContractAt("NexCasaV2", contractAddress);

  const tx = await contract.allowToken(tokenAddress, true);
  console.log(`⏳ TX terkirim: ${tx.hash}`);

  await tx.wait();
  console.log(`✅ Token ${tokenAddress} berhasil di-allow (TX: ${tx.hash})`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
