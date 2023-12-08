import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import deployDiamond from "../scripts/deploy";
import { getSelectors } from "../scripts/libraries/diamond";
import { DiamondCutFacet } from "../typechain-types";

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0].address;

  await deploy("SellFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  // await deploy("BuyFacet", {
  //   from: deployer,
  //   args: [],
  //   log: true,
  // });

  // await deploy("FloorFacet", {
  //   from: deployer,
  //   args: [],
  //   log: true,
  // });

  const sellFacet = await hre.ethers.getContract("SellFacet");
  // const buyFacet = await hre.ethers.getContract("BuyFacet");
  // const floorFacet = await hre.ethers.getContract("FloorFacet");

  const sellFacetSelectors: any = getSelectors(sellFacet);
  // const buyFacetSelectors: any = getSelectors(buyFacet);
  // const floorFacetSelectors: any = getSelectors(floorFacet);

  const diamondCutFacet: DiamondCutFacet = await ethers.getContractAt(
    "DiamondCutFacet",
    "0x781C0F94CF2F7C1030CA188B1778831714609799",
  );

  const cut = [
    {
      facetAddress: sellFacet.address,
      action: 1, //replace
      functionSelectors: sellFacetSelectors,
    },
    // {
    //   facetAddress: buyFacet.address,
    //   action: 1, //replace
    //   functionSelectors: buyFacetSelectors,
    // },
    // {
    //   facetAddress: floorFacet.address,
    //   action: 1, //replace
    //   functionSelectors: floorFacetSelectors,
    // },
  ];

  await diamondCutFacet.diamondCut([...cut], ethers.constants.AddressZero, "0x");
};

module.exports.tags = ["upgradeMock"];
