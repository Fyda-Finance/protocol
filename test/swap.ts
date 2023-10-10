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
      ethers.utils.parseUnits("20000000000", 6)
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
    const budget = "1000000000" // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(
      setup.strategyFacet.address,
      budget
    )

    await setup.strategyFacet.connect(setup.user).createStrategy(
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      "1500000000", // price: 1,500 usd
      budget
    );

    const strategy = await setup.strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      budget
    ]);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      "1200000000"
    );

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20USDC.address,
      "1000000"
    );

    await setup.tradeFacet.executeBuy(0, setup.scenarioDEX.address, dexCalldata);
  });

  it("should fail swap due to higher price impact", async function () {
    const budget = "1000000000" // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(
      setup.strategyFacet.address,
      budget
    )

    await setup.strategyFacet.connect(setup.user).createStrategy(
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      "1500000000", // price: 1,500 usd
      budget
    );

    const strategy = await setup.strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      budget
    ]);

    // 1 WETH = 1900 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      "1900000000"
    );

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20USDC.address,
      "1000000"
    );

    await expect(setup.tradeFacet.executeBuy(0, setup.scenarioDEX.address, dexCalldata)).to.be.reverted
  });

  it.only("exchange rate", async function () {
    const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
    const scenarioERC20WBTC = await scenarioERC20.deploy("WBTC", "WBTC", 8);

    let rate = await setup.tradeFacet.calculateExchangeRate(
      scenarioERC20WBTC.address,
      "10000000000", // 100 BTC <- input
      "1743810000000000000000", // 1743.81 ETH <- output
    )

    // 1 BTC is 17.4381 ETH
    expect(rate.toString()).to.equal("17438100000000000000")

    rate = await setup.tradeFacet.calculateExchangeRate(
      setup.scenarioERC20WETH.address,
      "100000000000000000000", // 100 ETH <- input
      "573000000", // 5.73 BTC <- output
    )

    // 1 ETH is 0.057 BTC
    expect(rate.toString()).to.equal("5730000")

    rate = await setup.tradeFacet.calculateExchangeRate(
      setup.scenarioERC20USDC.address,
      "50000000000", // 50k USDC <- input
      "200000000", // 2 BTC <- output
    )

    // 1 USDC is 0.00004 BTC
    expect(rate.toString()).to.equal("4000")

    rate = await setup.tradeFacet.calculateExchangeRate(
      scenarioERC20WBTC.address,
      "200000000", // 2 BTC <- output
      "50000000000", // 50k USDC <- input
    )

    // 1 BTC is 25k USDC
    expect(rate.toString()).to.equal("25000000000")
  })
});
