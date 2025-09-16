const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Setting APY (native token) with account:", deployer.address);

  const contractAddress = "0xAeB5B8E600274CD3A22F7EbFcDae0Ee45B7f4dc7"; // proxy NexCasa
  const nativeToken = "0x0000000000000000000000000000000000000000"; // address(0) untuk native token
  const apy = ethers.parseUnits("2500", 18);

  const contract = await ethers.getContractAt("NexCasa", contractAddress);

  const tx = await contract.setAPY(nativeToken, apy);
  await tx.wait();

  console.log(`✅ APY native token berhasil di-set ke ${apy}%`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
