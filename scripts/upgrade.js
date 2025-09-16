const { ethers, upgrades } = require("hardhat");

async function main() {
  
  const PROXY_ADDRESS = "0x7bCDE3057f596bfc9f5BaC3332591B1049d3b7Ce";

  console.log("Upgrading NexCasa contract...");

  // Dapatkan kontrak implementasi baru (NexCasaV2)
  const NexCasaV2 = await ethers.getContractFactory("NexCasaV2");

  // Lakukan upgrade pada kontrak proxy
  const nexCasa = await upgrades.upgradeProxy(PROXY_ADDRESS, NexCasaV2);

  console.log("NexCasa upgraded successfully!");
  console.log("Proxy address:", nexCasa.address);
  console.log("New implementation address:", await upgrades.erc1967.getImplementationAddress(nexCasa.address));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });