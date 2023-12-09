import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { OwnershipFacet } from "../typechain-types";

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const diamond = await hre.ethers.getContract("Diamond");
  const ownershipFacet: OwnershipFacet = await ethers.getContractAt("OwnershipFacet", diamond.address);
  const newOwner = "0x4BeA6238E0b0f1Fc40e2231B3093511C41F08585";

  await ownershipFacet.transferOwnership(newOwner);

  console.log("Ownership transfer complete");
};

module.exports.tags = ["transferOwnership"];
