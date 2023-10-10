import { ethers } from "hardhat";
import deployDiamond from "../scripts/deploy";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { expect } = require("chai");

describe("ScenarioDEX", function () {
  let diamondAddress: string;
  let diamondLoupeFacet: any;
  let scenarioERC20USDC: any;
  let scenarioERC20WETH: any;
  let scenarioDEX: any;
  let strategyFacet: any;
  let tradeFacet: any;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let tx;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    diamondAddress = await deployDiamond(owner);

    diamondLoupeFacet = await ethers.getContractAt(
      "DiamondLoupeFacet",
      diamondAddress
    );

    scenarioDEX = await ethers.getContractFactory("ScenarioDEX");
    scenarioDEX = await scenarioDEX.deploy();
    await scenarioDEX.deployed();

    const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
    scenarioERC20USDC = await scenarioERC20.deploy("USDC", "USDC", 6);
    await scenarioERC20USDC.deployed();

    scenarioERC20WETH = await scenarioERC20.deploy("WETH", "WETH", 18);
    await scenarioERC20WETH.deployed();

    tx = await scenarioERC20USDC.mint(
      user.address,
      ethers.utils.parseUnits("2000", 6)
    );
    tx.wait();
    strategyFacet = await ethers.getContractAt("StrategyFacet", diamondAddress);
    tradeFacet = await ethers.getContractAt("TradeFacet", diamondAddress);
  });

  it("should perform a swap correctly", async function () {
    await scenarioDEX.updateExchangeRate(
      scenarioERC20WETH.address,
      scenarioERC20USDC.address,
      "1200000000"
    );

    await strategyFacet.createStrategy(
      scenarioERC20WETH.address,
      scenarioERC20USDC.address,
      "1500000000",
      1
    );

    const strategy = await strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    await tradeFacet.executeBuy(0, scenarioDEX.address, "");
  });
});
