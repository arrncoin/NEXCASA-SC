const { ethers } = require("hardhat");

async function main() {
  // Alamat kontrak proxy Anda
  const PROXY_ADDRESS = "0xAeB5B8E600274CD3A22F7EbFcDae0Ee45B7f4dc7";

  // Alamat token reward yang akan ditambahkan
  const REWARD_TOKEN_ADDRESS = "0xF30FFbeFBfEdc5a60A50FA31e9A473EB75e3e629";

  // Jumlah token yang akan ditambahkan (450,000,000,000)
  // Perhatikan desimal token yang benar, ini contoh untuk 18 desimal
  const AMOUNT_TO_ADD = ethers.parseUnits("1000000000", 18);

  const [owner] = await ethers.getSigners();
  console.log("Adding reward from account:", owner.address);

  // Dapatkan instance kontrak token menggunakan IERC20
  // ethers.getContractAt adalah cara yang lebih tepat untuk berinteraksi dengan kontrak yang sudah dideploy
  const rewardToken = await ethers.getContractAt("IERC20", REWARD_TOKEN_ADDRESS);

  // Dapatkan instance kontrak staking
  const stakingContract = await ethers.getContractAt("NexCasaV2", PROXY_ADDRESS);

  // Langkah 1: Berikan persetujuan (approval) ke kontrak staking
  console.log("Approving token transfer...");
  const approveTx = await rewardToken.approve(PROXY_ADDRESS, AMOUNT_TO_ADD);
  await approveTx.wait();
  console.log("Approval successful! Tx hash:", approveTx.hash);

  // Langkah 2: Panggil fungsi addReward pada kontrak staking
  console.log("Adding reward to the pool...");
  const addRewardTx = await stakingContract.addReward(REWARD_TOKEN_ADDRESS, AMOUNT_TO_ADD);
  await addRewardTx.wait();
  console.log("Reward added successfully! Tx hash:", addRewardTx.hash);

  console.log(`Successfully added ${ethers.formatUnits(AMOUNT_TO_ADD, 18)} tokens to the reward pool.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });