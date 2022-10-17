import hre from "hardhat";
import { ethers } from "hardhat";

async function main() {

  let CETHToken = process.env.CETH_TOKEN !== undefined && process.env.CETH_TOKEN !== '' ? process.env.CETH_TOKEN : '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';
  let PriceFeed = process.env.PRICE_FEED !== undefined && process.env.PRICE_FEED !== '' ? process.env.PRICE_FEED : '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

  const DevUSDC = await ethers.getContractFactory("ERC20Dev");
  const devUSDC = await DevUSDC.deploy();

  console.log("DevUSDC deployed to: ", devUSDC.address);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(CETHToken, devUSDC.address, PriceFeed);

  console.log("Staking deployed to: ", staking.address);

  // const totalSupply = await devUSDC.totalSupply();

  // await devUSDC.approve(staking.address, totalSupply);

  // console.log('Transfer rewards for staking approve!');

  // await hre.run("verify:verify", {
  //   address: devUSDC.address,
  //   constructorArguments: [],
  //   contract: "contracts/mock/ERC20Dev.sol:ERC20Dev"
  // });

  // console.log("Verified Reward tojen contract");

  // await hre.run("verify:verify", {
  //   address: staking.address,
  //   constructorArguments: [
  //     CETHToken, 
  //     devUSDC.address, 
  //     PriceFeed
  //   ],
  //   contract: "contracts/Staking.sol:Staking"
  // });

  // console.log("Verified Staking contract");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
