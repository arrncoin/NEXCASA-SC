// scripts/deployfaucet.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with", deployer.address);

  const CustomERC20 = await ethers.getContractFactory("CustomERC20");
  const Faucet = await ethers.getContractFactory("TokenFaucet");

  const supply = "1000000"; // 1,000,000

  console.log("Deploying BTC token...");
  const btc = await CustomERC20.deploy("Mock Bitcoin", "BTC", 18, supply, deployer.address);
  await btc.waitForDeployment();
  console.log("BTC at", await btc.getAddress());

  console.log("Deploying ETH token...");
  const eth = await CustomERC20.deploy("Mock Ether", "ETH", 18, supply, deployer.address);
  await eth.waitForDeployment();
  console.log("ETH at", await eth.getAddress());

  console.log("Deploying USDT token...");
  const usdt = await CustomERC20.deploy("Mock Tether", "USDT", 18, supply, deployer.address);
  await usdt.waitForDeployment();
  console.log("USDT at", await usdt.getAddress());

  console.log("Deploying USDC token...");
  const usdc = await CustomERC20.deploy("Mock USD Coin", "USDC", 18, supply, deployer.address);
  await usdc.waitForDeployment();
  console.log("USDC at", await usdc.getAddress());

  console.log("Deploying Faucet...");
  const faucet = await Faucet.deploy(deployer.address);
  await faucet.waitForDeployment();
  console.log("Faucet at", await faucet.getAddress());

  // Transfer stok ke faucet
  const amountToFaucet = ethers.parseUnits("100000", 18);
  console.log("Transferring tokens to faucet...");
  await (await btc.transfer(await faucet.getAddress(), amountToFaucet)).wait();
  await (await eth.transfer(await faucet.getAddress(), amountToFaucet)).wait();
  await (await usdt.transfer(await faucet.getAddress(), amountToFaucet)).wait();
  await (await usdc.transfer(await faucet.getAddress(), amountToFaucet)).wait();

  // Config faucet (1 hari = 86400 detik)
  console.log("Configuring faucet...");
  await (await faucet.setTokenConfig(await btc.getAddress(), ethers.parseUnits("0.1", 18), 86400, true)).wait();
  await (await faucet.setTokenConfig(await eth.getAddress(), ethers.parseUnits("10", 18), 86400, true)).wait();
  await (await faucet.setTokenConfig(await usdt.getAddress(), ethers.parseUnits("100", 18), 86400, true)).wait();
  await (await faucet.setTokenConfig(await usdc.getAddress(), ethers.parseUnits("100", 18), 86400, true)).wait();

  console.log("✅ Deploy & setup done!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
