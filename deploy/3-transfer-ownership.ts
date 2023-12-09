import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { OwnershipFacet } from "../typechain-types";

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const diamond = await hre.ethers.getContract("Diamond");
  const ownershipFacet: OwnershipFacet = await ethers.getContractAt("OwnershipFacet", diamond.address);
  const newOwner = "";

  await ownershipFacet.transferOwnership(newOwner);

  console.log("Configuration complete");
};

module.exports.tags = ["configureFeeds"];
