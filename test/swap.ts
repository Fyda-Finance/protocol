import { ethers } from "hardhat";
import deployDiamond from "../scripts/deploy";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ScenarioDEX,
  ScenarioERC20,
  ScenarioFeedRegistry,
  StrategyFacet,
  TradeFacet,
} from "../typechain-types";
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
  scenarioFeedRegistry: ScenarioFeedRegistry;
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

    const strategyFacet = await ethers.getContractAt(
      "StrategyFacet",
      diamondAddress
    );
    const tradeFacet = await ethers.getContractAt("TradeFacet", diamondAddress);

    const ScenarioFeedRegistry = await ethers.getContractFactory(
      "ScenarioFeedRegistry"
    );
    const scenarioFeedRegistry = await ScenarioFeedRegistry.deploy();

    await tradeFacet.setChainlinkFeedRegistry(scenarioFeedRegistry.address);

    return {
      scenarioERC20USDC,
      scenarioERC20WETH,
      scenarioDEX,
      owner,
      user,
      strategyFacet,
      tradeFacet,
      scenarioFeedRegistry,
    };
  }

  let setup: SetupDiamondFixture;

  beforeEach(async function () {
    setup = await loadFixture(setupDiamondFixture);
  });

  it("should perform a swap correctly", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);

    let parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: 0,
      _slippage: 1000,
      _floor: false,
      _floorType: 0,
      _floorAt: 0,
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: true,
      _buyType: 1,
      _buyAt: "1500000000000000000000",
      _buyValue: 1,
      _sell: false,
      _sellType: 0,
      _sellAt: 0,
      _highSellValue: 0,
      _str: false,
      _strValue: 0,
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: 0,
      _sellTwap: false,
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btd: false,
      _btdValue: 0,
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: 0,
    };

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const strategy = await setup.strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      budget,
    ]);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      "120000000000"
    );

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20USDC.address,
      "100000000"
    );

    await setup.scenarioFeedRegistry.updatePrice(
      setup.scenarioERC20WETH.address,
      "120000000000"
    );

    await setup.scenarioFeedRegistry.updatePrice(
      setup.scenarioERC20USDC.address,
      "100000000"
    );

    await setup.tradeFacet.executeBuy(
      0,
      setup.scenarioDEX.address,
      dexCalldata
    );
  });

  it("should fail swap due to higher price impact", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);

    let parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: 0,
      _slippage: 1000,
      _floor: false,
      _floorType: 0,
      _floorAt: 0,
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: true,
      _buyType: 1,
      _buyAt: 1500000000,
      _buyValue: 1,
      _sell: false,
      _sellType: 0,
      _sellAt: 0,
      _highSellValue: 0,
      _str: false,
      _strValue: 0,
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: 0,
      _sellTwap: false,
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btd: false,
      _btdValue: 0,
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: 0,
    };

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const strategy = await setup.strategyFacet.nextStartegyId();
    expect(strategy).to.equal(1);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      budget,
    ]);

    // 1 WETH = 1900 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      "190000000000"
    );

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20USDC.address,
      "100000000"
    );

    await expect(
      setup.tradeFacet.executeBuy(0, setup.scenarioDEX.address, dexCalldata)
    ).to.be.reverted;
  });

  it("exchange rate", async function () {
    const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
    const scenarioERC20WBTC = await scenarioERC20.deploy("WBTC", "WBTC", 8);

    let rate = await setup.tradeFacet.calculateExchangeRate(
      scenarioERC20WBTC.address,
      "10000000000", // 100 BTC <- input
      "1743810000000000000000" // 1743.81 ETH <- output
    );

    // 1 BTC is 17.4381 ETH
    expect(rate.toString()).to.equal("17438100000000000000");

    rate = await setup.tradeFacet.calculateExchangeRate(
      setup.scenarioERC20WETH.address,
      "100000000000000000000", // 100 ETH <- input
      "573000000" // 5.73 BTC <- output
    );

    // 1 ETH is 0.057 BTC
    expect(rate.toString()).to.equal("5730000");

    rate = await setup.tradeFacet.calculateExchangeRate(
      setup.scenarioERC20USDC.address,
      "50000000000", // 50k USDC <- input
      "200000000" // 2 BTC <- output
    );

    // 1 USDC is 0.00004 BTC
    expect(rate.toString()).to.equal("4000");

    rate = await setup.tradeFacet.calculateExchangeRate(
      scenarioERC20WBTC.address,
      "200000000", // 2 BTC <- output
      "50000000000" // 50k USDC <- input
    );

    // 1 BTC is 25k USDC
    expect(rate.toString()).to.equal("25000000000");
  });

  it("slippage", async function () {
    // buy with better rate example
    // price = 1500,000000
    // exchangeRate = 1450,000000
    // slippage = (1500 * 10000) / 1450 = 103.44%
    await expect(
      setup.tradeFacet.validateSlippage(1450000000, 1500000000, 500, true)
    ).to.not.be.reverted;

    // buy with bad rate example
    // price = 1500,000000
    // exchangeRate = 1550,000000
    // slippage = (1500 * 10000) / 1550 = 96.77%
    await expect(
      setup.tradeFacet.validateSlippage(1550000000, 1500000000, 200, true)
    ).to.be.reverted;

    // sell with better rate example
    // price = 1500,000000
    // exchangeRate = 1600,000000
    // slippage = (1500 * 10000) / 1600 = 93.75%
    await expect(
      setup.tradeFacet.validateSlippage(1600000000, 1500000000, 500, false)
    ).to.not.be.reverted;

    // sell with bad rate example
    // price = 1500,000000
    // exchangeRate = 1300,000000
    // slippage = (1500 * 10000) / 1300 = 115.38%
    await expect(
      setup.tradeFacet.validateSlippage(1300000000, 1500000000, 500, false)
    ).to.be.reverted;
  });
});
