import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const feeds: any = {
  sepolia: {
    WBTC: "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43",
    WETH: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    LINK: "0xc59E3633BAAC79493d908e63626716e204A45EdF",
    USDC: "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E",
  },
};

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0].address;

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

  let link = await hre.ethers.getContract("LINK");
  let wbtc = await hre.ethers.getContract("WBTC");
  let weth = await hre.ethers.getContract("WETH");
  let usdc = await hre.ethers.getContract("USDC");

  await deploy("MockDEX", {
    contract: "ScenarioDEX",
    from: deployer,
    args: [],
    log: true,
  });

  let dex = await hre.ethers.getContract("MockDEX");

  let tx = await dex.updateFeed(usdc.address, feeds[network.name]["USDC"]);
  await tx.wait();

  tx = await dex.updateFeed(wbtc.address, feeds[network.name]["WBTC"]);
  await tx.wait();

  tx = await dex.updateFeed(weth.address, feeds[network.name]["WETH"]);
  await tx.wait();

  tx = await dex.updateFeed(link.address, feeds[network.name]["LINK"]);
  await tx.wait();

  tx = await dex.updateSlippage(10); // 0.1%;
  await tx.wait();
};

module.exports.tags = ["deployMock"];
