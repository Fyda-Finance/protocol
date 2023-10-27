import deployDiamond from "../scripts/deploy";
import {
  ScenarioDEX,
  ScenarioERC20,
  ScenarioFeedAggregator,
  StrategyFacet,
  BuyFacet,
} from "../typechain";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

const { expect } = require("chai");

type SetupDiamondFixture = {
  scenarioERC20USDC: ScenarioERC20;
  scenarioERC20WETH: ScenarioERC20;
  scenarioDEX: ScenarioDEX;
  strategyFacet: StrategyFacet;
  buyFacet: BuyFacet;
  owner: SignerWithAddress;
  user: SignerWithAddress;
  usdcScenarioFeedAggregator: ScenarioFeedAggregator;
  wethScenarioFeedAggregator: ScenarioFeedAggregator;
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
    const buyFacet = await ethers.getContractAt("BuyFacet", diamondAddress);

    const priceOracleFacet = await ethers.getContractAt(
      "PriceOracleFacet",
      diamondAddress
    );

    const ScenarioFeedAggregator = await ethers.getContractFactory(
      "ScenarioFeedAggregator"
    );
    const usdcScenarioFeedAggregator: ScenarioFeedAggregator =
      await ScenarioFeedAggregator.deploy();
    const wethScenarioFeedAggregator: ScenarioFeedAggregator =
      await ScenarioFeedAggregator.deploy();

    await priceOracleFacet.setAssetFeed(
      scenarioERC20USDC.address,
      usdcScenarioFeedAggregator.address
    );
    await priceOracleFacet.setAssetFeed(
      scenarioERC20WETH.address,
      wethScenarioFeedAggregator.address
    );

    return {
      scenarioERC20USDC,
      scenarioERC20WETH,
      scenarioDEX,
      strategyFacet,
      buyFacet,
      owner,
      user,
      usdcScenarioFeedAggregator,
      wethScenarioFeedAggregator,
    };
  }

  let setup: SetupDiamondFixture;

  beforeEach(async function () {
    setup = await loadFixture(setupDiamondFixture);
  });

  it("All strategy based", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);

    const parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: "0",
      _slippage: 1000,
      _floor: false,
      _floorType: 0,
      _floorValue: "0",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: true,
      _buyType: 1,
      _buyValue: "1500000000",
      _sell: false,
      _sellType: 0,
      _sellValue: "0",
      _highSellValue: 0,
      _str: false,
      _strValue: 0,
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: "0",
      _sellTwap: false,
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btd: false,
      _btdValue: "0",
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: "0",
      _current_price: 0,
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000");

    await setup.usdcScenarioFeedAggregator.setPrice("100000000");

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStartegyId()).to.equal(1);
    expect(await setup.strategyFacet.getStrategy(5)).to.be.reverted;

    parameters._floor = true;

    await expect(
      setup.strategyFacet.connect(setup.user).createStrategy(parameters)
    ).to.be.reverted;
    parameters._floorValue = "1000000000";

    await expect(
      setup.strategyFacet.connect(setup.user).createStrategy(parameters)
    ).to.be.reverted;
    parameters._floorType = 1;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStartegyId()).to.equal(2);

    parameters._floor = false;
    parameters._floorValue = "0";
    parameters._btd = true;
    parameters._buyTwap = true;
    await expect(
      setup.strategyFacet.connect(setup.user).createStrategy(parameters)
    ).to.be.reverted;
    parameters._buyTwap = false;
    await expect(
      setup.strategyFacet.connect(setup.user).createStrategy(parameters)
    ).to.be.reverted;
    parameters._btdType = 1;
    parameters._btdValue = "15000";
    parameters._buyDCAUnit = 1;
    parameters._buyDCAValue = "12";

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await expect(await setup.strategyFacet.nextStartegyId()).to.equal(3);

    parameters._buy = false;
    parameters._buyValue = "0";
    parameters._btd = false;
    parameters._sellTwap = true;
    parameters._sell = true;
    parameters._sellType = 1;
    parameters._sellValue = "120000000";
    parameters._investAmount = "100000";

    await expect(
      setup.strategyFacet.connect(setup.user).createStrategy(parameters)
    ).to.be.reverted;

    parameters._sellTwapTime = 1;
    parameters._sellTwapTimeUnit = 1;
    parameters._sellDCAUnit = 1;
    parameters._sellDCAValue = "12";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStartegyId()).to.equal(4);
  });
});
