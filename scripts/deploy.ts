/* eslint prefer-const: "off" */
import { FacetCutAction, getSelectors } from "./libraries/diamond";
import { ethers } from "hardhat";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";

async function deployDiamond(contractOwner?: SignerWithAddress, log?: boolean) {
  if (!contractOwner) {
    const accounts = await ethers.getSigners();
    contractOwner = accounts[0];
  }

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();
  if (log) {
    console.log("DiamondCutFacet deployed:", diamondCutFacet.address);
  }

  // deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(
    contractOwner.address,
    diamondCutFacet.address
  );
  await diamond.deployed();
  if (log) {
    console.log("Diamond deployed:", diamond.address);
  }

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  if (log) {
    console.log("DiamondInit deployed:", diamondInit.address);
  }

  // deploy facets
  if (log) {
    console.log("");
    console.log("Deploying facets");
  }
  const FacetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "StrategyFacet",
    "BuyFacet",
    "SellFacet",
    "FloorFacet",
    "PriceOracleFacet",
    "LensFacet",
  ];
  const cut = [];
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy();
    await facet.deployed();
    if (log) {
      console.log(`${FacetName} deployed: ${facet.address}`);
    }
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  // upgrade diamond with facets
  // console.log("");
  // console.log("Diamond Cut:", cut);
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
  let tx;
  let receipt;
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData("init");
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
  if (log) {
    console.log("Diamond cut tx: ", tx.hash);
  }
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  if (log) {
    console.log("Completed diamond cut");
  }
  return diamond.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

export default deployDiamond;
