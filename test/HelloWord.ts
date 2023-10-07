import { expect } from "chai";
import { ethers } from "hardhat";

describe("Diamond Proxy", function () {
  let owner, diamond, helloWorldFacet;

  // Deploy the Diamond and HelloWorldFacet contracts before each test
  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // Deploy the HelloWorldFacet contract
    const HelloWorldFacet = await ethers.getContractFactory("HelloWorldFacet");
    helloWorldFacet = await HelloWorldFacet.deploy();
    helloWorldFacet.deploymentTransaction();

    // Deploy the Diamond contract with the HelloWorldFacet as a facet
    const address = await helloWorldFacet.getAddress();
    const Diamond = await ethers.getContractFactory("Diamond");
    diamond = await Diamond.deploy(owner.address, address);
    diamond.deploymentTransaction();
  });

  it("should return the same message from Diamond as from HelloWorldFacet", async function () {
    // Call getMessage from HelloWorldFacet directly

    const directMessage = await helloWorldFacet.getMessage();
    console.log("Direct Message: ", directMessage);

    // Call getMessage through the Diamond contract proxy
    const diamondMessage = await diamond.callStatic.getMessage();
    console.log("Diamond Message: ", diamondMessage);

    // Compare the return values
    expect(diamondMessage).to.equal(directMessage);
  });
});
