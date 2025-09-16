const { ethers } = require("hardhat");

async function main() {
  const CONTRACT_ADDRESS = "0xB89D9b88B3627b44558e79B8F91033dEAa5781ef"; // ganti sc kamu
  const [signer] = await ethers.getSigners();

  console.log("Calling initialize from:", signer.address);

  const ABI = [
    "function initialize(address owner_) external",
    "function owner() view returns (address)"
  ];

  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

  // Panggil initialize dengan wallet kamu sebagai owner
  const tx = await contract.initialize(signer.address);
  await tx.wait();

  console.log("✅ Initialize done, owner set to:", signer.address);

  const newOwner = await contract.owner();
  console.log("🔑 Current owner:", newOwner);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
