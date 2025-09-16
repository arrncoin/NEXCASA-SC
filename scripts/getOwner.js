const { ethers } = require("hardhat");

async function main() {
  // Ganti dengan alamat kontrak NexCasaV2 kamu di network nexus
  const CONTRACT_ADDRESS = "0xB89D9b88B3627b44558e79B8F91033dEAa5781ef";

  // Import ABI dari file atau langsung pakai minimal ABI
  const ABI = [
    "function owner() view returns (address)"
  ];

  const [signer] = await ethers.getSigners();
  console.log("Checking from account:", signer.address);

  // Buat instance contract
  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

  // Panggil fungsi owner()
  const owner = await contract.owner();
  console.log("✅ Owner of NexCasaV2:", owner);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Error:", err);
    process.exit(1);
  });
