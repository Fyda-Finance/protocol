import { LedgerSigner } from "@anders-t/ethers-ledger";
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

  await deploy("FloorFacet", {
    from: deployer,
    args: [],
    log: true,
  });

  const sellFacet = await hre.ethers.getContract("SellFacet");
  // const buyFacet = await hre.ethers.getContract("BuyFacet");
  const floorFacet = await hre.ethers.getContract("FloorFacet");

  const sellFacetSelectors: any = getSelectors(sellFacet);
  // const buyFacetSelectors: any = getSelectors(buyFacet);
  const floorFacetSelectors: any = getSelectors(floorFacet);

  const diamond = await hre.ethers.getContract("Diamond");

  const diamondCutFacet: DiamondCutFacet = await ethers.getContractAt("DiamondCutFacet", diamond.address);

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
    {
      facetAddress: floorFacet.address,
      action: 1, //replace
      functionSelectors: floorFacetSelectors,
    },
  ];

  let signer;
  if (network.name !== "sepolia") {
    signer = new LedgerSigner(hre.ethers.provider);
  } else {
    signer = accounts[0];
  }

  const tx = await diamondCutFacet.connect(signer).diamondCut([...cut], ethers.constants.AddressZero, "0x");
  console.log("Hash:", tx.hash);
  await tx.wait();
};

module.exports.tags = ["upgradeDiamond"];
