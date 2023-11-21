import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { PriceOracleFacet, ScenarioDEX } from "typechain";

import deployDiamond from "../scripts/deploy";

const feeds: any = {
  goerli: {
    usdc: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7",
    wbtc: "0xA39434A63A52E749F02807ae27335515BA4b07F7",
    eth: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    link: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
  },
};

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0].address;

  /**
   * 1. Deploy ERC20 Tokens
   * 2. Deploy DEX
   * 3. Deploy Diamond
   * 3. Configure Price for ERC20 in DEX and Diamond
   */

  await deploy("WBTC", {
    contract: "ScenarioERC20",
    from: deployer,
    args: ["Wrapped Bitcoin", "WBTC", 8],
    log: true,
  });

  await deploy("USDC", {
    contract: "ScenarioERC20",
    from: deployer,
    args: ["USD Coin", "USDC", 6],
    log: true,
  });

  await deploy("WETH", {
    contract: "ScenarioBasicERC20",
    from: deployer,
    args: ["Wrapped Ether", "WETH", 18],
    log: true,
  });

  await deploy("LINK", {
    contract: "ScenarioBasicERC20",
    from: deployer,
    args: ["Chainlink", "LINK", 18],
    log: true,
  });

  const usdc = await hre.ethers.getContract("USDC");
  const wbtc = await hre.ethers.getContract("WBTC");
  const weth = await hre.ethers.getContract("WETH");
  const link = await hre.ethers.getContract("LINK");

  await deploy("MockDEX", {
    contract: "ScenarioDEX",
    from: deployer,
    args: [],
    log: true,
  });

  const dex: ScenarioDEX = await hre.ethers.getContract("MockDEX");
  const diamondAddress = await deployDiamond(accounts[0], true);

  const priceOracleFacet: PriceOracleFacet = await ethers.getContractAt("PriceOracleFacet", diamondAddress);
  await priceOracleFacet.setAssetFeed(usdc.address, feeds[network.name].usdc);
  await priceOracleFacet.setAssetFeed(wbtc.address, feeds[network.name].wbtc);
  await priceOracleFacet.setAssetFeed(weth.address, feeds[network.name].eth);
  await priceOracleFacet.setAssetFeed(link.address, feeds[network.name].link);

  await dex.updateFeed(usdc.address, feeds[network.name].usdc);
  await dex.updateFeed(wbtc.address, feeds[network.name].wbtc);
  await dex.updateFeed(weth.address, feeds[network.name].eth);
  await dex.updateFeed(link.address, feeds[network.name].link);

  await dex.updateSlippage(10); // 0.1%;

  console.log("Deployed completed");
};

module.exports.tags = ["deployMock"];
