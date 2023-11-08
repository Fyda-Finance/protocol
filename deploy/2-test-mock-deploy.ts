import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { PriceOracleFacet, ScenarioDEX } from "typechain";

import deployDiamond from "../scripts/deploy";

const addresses: any = {
  goerli: {
    usdc: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7",
    wbtc: "0xA39434A63A52E749F02807ae27335515BA4b07F7",
    eth: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    link: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
    diamond: "0x29894a2F6f9FA2F3E0Be08465Af2Ca572d962687",
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

  const priceOracleFacet: PriceOracleFacet = await ethers.getContractAt(
    "PriceOracleFacet",
    addresses[network.name].diamond,
  );
};

module.exports.tags = ["testMock"];
