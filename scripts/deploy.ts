import { ethers } from "hardhat";

async function main() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  const HelloWorldFacet = await ethers.getContractFactory("HelloWorldFacet");
  const helloWorldFacet = await HelloWorldFacet.deploy();
  helloWorldFacet.deploymentTransaction();
  console.log("DiamondCutFacet deployed:", await helloWorldFacet.getAddress());

  // deploy Diamond
  const address = await helloWorldFacet.getAddress();

  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(contractOwner.address, address);
  diamond.deploymentTransaction();
  console.log("Diamond deployed:", await diamond.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
