import { ethers } from "hardhat";
import deployDiamond from "../scripts/deploy";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ScenarioDEX, ScenarioERC20, StrategyFacet, TradeFacet } from "../typechain-types";
const { expect } = require("chai");
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

type SetupDiamondFixture = {
  scenarioERC20USDC: ScenarioERC20;
  scenarioERC20WETH: ScenarioERC20;
  scenarioDEX: ScenarioDEX;
  strategyFacet: StrategyFacet;
  tradeFacet: TradeFacet;
  owner: SignerWithAddress;
  user: SignerWithAddress;
};

describe("ScenarioDEX", function () {
  async function setupDiamondFixture(): Promise<SetupDiamondFixture> {
    const [owner, user] = await ethers.getSigners();

    const diamondAddress = await deployDiamond(owner);

    const ScenarioDEX = await ethers.getContractFactory("ScenarioDEX");
    const scenarioDEX = await ScenarioDEX.deploy();

    const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
    const scenarioERC20USDC = await scenarioERC20.deploy("USDC", "USDC", 6);
    const scenarioERC20WETH = await scenarioERC20.deploy("WETH", "WETH", 18);

    await scenarioERC20USDC.mint(
      user.address,
      ethers.utils.parseUnits("2000", 6)
    );

    const strategyFacet = await ethers.getContractAt("StrategyFacet", diamondAddress);
    const tradeFacet = await ethers.getContractAt("TradeFacet", diamondAddress);

    return {
      scenarioERC20USDC,
      scenarioERC20WETH,
      scenarioDEX,
      owner,
      user,
      strategyFacet,
      tradeFacet,
    }
  }

  let setup: SetupDiamondFixture;

  beforeEach(async function () {
    setup = await loadFixture(setupDiamondFixture);
  });

  it("should perform a swap correctly", async function () {
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      "1200000000"
    );

    await setup.strategyFacet.createStrategy(
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      "1500000000",
      1
    );

    const strategy = await setup.strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    // await setup.tradeFacet.executeBuy(0, setup.scenarioDEX.address, "");
  });
});
