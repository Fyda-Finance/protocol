import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import deployDiamond from "../scripts/deploy";
import { getSelectors } from "../scripts/libraries/diamond";
import { PriceOracleFacet, ScenarioDEX } from "../typechain-types";

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

  await deploy("DiamondCutFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  const diamondCutFacet = await hre.ethers.getContract("DiamondCutFacet");

  await deploy("Diamond", {
    from: deployer,
    args: [deployer, diamondCutFacet.address],
    log: true,
  });

  await deploy("DiamondInit", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("DiamondLoupeFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("OwnershipFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("StrategyFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("BuyFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("SellFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("FloorFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("PriceOracleFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy("LensFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  const sellFacet = await hre.ethers.getContract("SellFacet");
  const buyFacet = await hre.ethers.getContract("BuyFacet");
  const floorFacet = await hre.ethers.getContract("FloorFacet");
  const priceOracleFacet = await hre.ethers.getContract("PriceOracleFacet");
  const strategyFacet = await hre.ethers.getContract("StrategyFacet");
  const ownershipFacet = await hre.ethers.getContract("OwnershipFacet");
  const diamondLoupeFacet = await hre.ethers.getContract("DiamondLoupeFacet");
  const lensFacet = await hre.ethers.getContract("LensFacet");

  const sellFacetSelectors: any = getSelectors(sellFacet);
  const buyFacetSelectors: any = getSelectors(buyFacet);
  const floorFacetSelectors: any = getSelectors(floorFacet);
  const priceOracleFacetSelectors: any = getSelectors(priceOracleFacet);
  const strategyFacetSelectors: any = getSelectors(strategyFacet);
  const ownershipFacetSelectors: any = getSelectors(ownershipFacet);
  const diamondLoupeFacetSelectors: any = getSelectors(diamondLoupeFacet);
  const lensFacetSelectors: any = getSelectors(lensFacet);

  const cut = [
    {
      facetAddress: sellFacet.address,
      action: 0,
      functionSelectors: sellFacetSelectors,
    },
    {
      facetAddress: buyFacet.address,
      action: 0,
      functionSelectors: buyFacetSelectors,
    },
    {
      facetAddress: floorFacet.address,
      action: 0,
      functionSelectors: floorFacetSelectors,
    },
    {
      facetAddress: priceOracleFacet.address,
      action: 0,
      functionSelectors: priceOracleFacetSelectors,
    },
    {
      facetAddress: strategyFacet.address,
      action: 0,
      functionSelectors: strategyFacetSelectors,
    },
    {
      facetAddress: ownershipFacet.address,
      action: 0,
      functionSelectors: ownershipFacetSelectors,
    },
    {
      facetAddress: diamondLoupeFacet.address,
      action: 0,
      functionSelectors: diamondLoupeFacetSelectors,
    },
    {
      facetAddress: lensFacet.address,
      action: 0,
      functionSelectors: lensFacetSelectors,
    },
  ];

  const diamond = await hre.ethers.getContract("Diamond");
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
  const diamondInit = await hre.ethers.getContract("DiamondInit");

  const functionCall = diamondInit.interface.encodeFunctionData("init");
  const tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
  await tx.wait();

  console.log("Diamond Deployed successfully");
};

module.exports.tags = ["deployDiamond"];
