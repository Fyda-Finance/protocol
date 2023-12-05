import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";

import deployDiamond from "../scripts/deploy";
import { BuyFacet, ScenarioDEX, ScenarioERC20, ScenarioFeedAggregator, StrategyFacet } from "../typechain-types";
import { Parameters } from "./utils";

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

describe("Strategy", function () {
  async function setupDiamondFixture(): Promise<SetupDiamondFixture> {
    const [owner, user] = await ethers.getSigners();

    const diamondAddress = await deployDiamond(owner);

    const ScenarioDEX = await ethers.getContractFactory("ScenarioDEX");
    const scenarioDEX = (await ScenarioDEX.deploy()) as ScenarioDEX;

    const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
    const scenarioERC20USDC = (await scenarioERC20.deploy("USDC", "USDC", 6)) as ScenarioERC20;
    const scenarioERC20WETH = (await scenarioERC20.deploy("WETH", "WETH", 18)) as ScenarioERC20;

    await scenarioERC20USDC.mint(user.address, ethers.utils.parseUnits("20000000000", 6));

    const strategyFacet: StrategyFacet = await ethers.getContractAt("StrategyFacet", diamondAddress);
    const buyFacet: BuyFacet = await ethers.getContractAt("BuyFacet", diamondAddress);

    const priceOracleFacet = await ethers.getContractAt("PriceOracleFacet", diamondAddress);

    const ScenarioFeedAggregator = await ethers.getContractFactory("ScenarioFeedAggregator");
    const usdcScenarioFeedAggregator = (await ScenarioFeedAggregator.deploy()) as ScenarioFeedAggregator;
    const wethScenarioFeedAggregator = (await ScenarioFeedAggregator.deploy()) as ScenarioFeedAggregator;

    await priceOracleFacet.setAssetFeed(scenarioERC20USDC.address, usdcScenarioFeedAggregator.address);
    await priceOracleFacet.setAssetFeed(scenarioERC20WETH.address, wethScenarioFeedAggregator.address);

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
  let parameters: Parameters;

  beforeEach(async function () {
    setup = await loadFixture(setupDiamondFixture);
    parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: "0",
      _investAmount: "0",
      _impact: 1000,
      _floorType: 0,
      _floorValue: "0",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buyType: 0,
      _buyValue: "0",
      _sellType: 0,
      _sellValue: "0",
      _highSellValue: "0",
      _strValue: "0",
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: "0",
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btdValue: "0",
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: "0",
      _current_price: 0,
    };
  });

  it("Error Checks", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    const parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: "0",
      _impact: 1000,
      _floorType: 0,
      _floorValue: "0",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buyType: 1,
      _buyValue: "1500000000",
      _sellType: 0,
      _sellValue: "0",
      _highSellValue: 0,
      _strValue: 0,
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: "0",
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btdValue: "0",
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: "0",
      _current_price: 0,
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStrategyId()).to.equal(1);
    expect(await setup.strategyFacet.getStrategy(5)).to.be.reverted;

    parameters._floorValue = "1000000000";
    parameters._floorType = 1;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStrategyId()).to.equal(2);

    parameters._floorValue = "0";
    parameters._btdType = 1;
    parameters._btdValue = "15000";
    parameters._buyDCAUnit = 1;
    parameters._buyDCAValue = "12";

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await expect(await setup.strategyFacet.nextStrategyId()).to.equal(3);
    parameters._buyValue = "10000";
    parameters._sellType = 1;
    parameters._sellValue = "120000000";
    parameters._investAmount = "100000";
    parameters._stableAmount = "0";

    // await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;

    parameters._sellTwapTime = 1;
    parameters._sellTwapTimeUnit = 1;
    parameters._sellDCAUnit = 1;
    parameters._sellDCAValue = "12";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    expect(await setup.strategyFacet.nextStrategyId()).to.equal(4);
  });

  it("Both DCA chosen", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    const parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20WETH.address,
      _stableAmount: budget,
      _investAmount: budget,
      _impact: 1000,
      _floorType: 1,
      _floorValue: "1600000000",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buyType: 1,
      _buyValue: "1500000000",
      _sellType: 2,
      _sellValue: "1000000",
      _highSellValue: "1550000000",
      _strValue: "0",
      _strType: 1,
      _sellDCAUnit: 2,
      _sellDCAValue: "1000",
      _sellTwapTime: 1,
      _sellTwapTimeUnit: 1,
      _completeOnSell: false,
      _buyTwapTime: 1,
      _buyTwapTimeUnit: 1,
      _btdValue: "0",
      _btdType: 1,
      _buyDCAUnit: 2,
      _buyDCAValue: "1000",
      _current_price: 0,
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._stableToken = setup.scenarioERC20USDC.address;
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._floorValue = "100000000";

    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._buyTwapTime = 0;
    parameters._buyTwapTimeUnit = 0;
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._sellTwapTime = 0;
    parameters._sellTwapTimeUnit = 0;
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._sellValue = "1600000000";
    parameters._sellType = 1;
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._sellTwapTime = 0;
    parameters._investAmount = "0";
    parameters._strValue = "1000";
    await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._highSellValue = "1650000000";
    // await expect(setup.strategyFacet.connect(setup.user).createStrategy(parameters)).to.be.reverted;
    parameters._btdValue = "1000";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
  });

  it("Update Strategy", async function () {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    parameters._buyType = 1;
    parameters._buyValue = "1500000000";
    parameters._stableAmount = budget;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    const param = {
      sellValue: "0",
      buyValue: "0",
      floorValue: "0",
      highSellValue: "0",
      buyTwapTime: 0,
      buyTwapTimeUnit: 0,
      buyDCAValue: "0",
      sellDCAValue: "0",
      sellTwapTime: 0,
      sellTwapTimeUnit: 0,
      strValue: "0",
      btdValue: "0",
      toggleCompleteOnSell: false,
      toggleLiquidateOnFloor: false,
      toggleCancelOnFloor: false,
      impact: "0",
      current_price: 0,
    };

    await expect(setup.strategyFacet.connect(setup.owner).updateStrategy(0, param)).to.be.reverted;
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(0, param)).to.be.reverted;
    param.sellValue = "10000";
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(0, param)).to.be.reverted;
    await setup.strategyFacet.connect(setup.user).cancelStrategy(0);
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(0, param)).to.be.reverted;
    parameters._sellType = 1;
    parameters._sellValue = "1600000000";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(1, param)).to.be.reverted;
    param.btdValue = "50000";
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(1, param)).to.be.reverted;
    parameters._btdType = 3;
    parameters._btdValue = "500000000";
    parameters._buyDCAUnit = 2;
    parameters._buyDCAValue = "500000000";
    param.sellValue = "1900000000";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.strategyFacet.connect(setup.user).updateStrategy(2, param);
    param.buyTwapTime = 1;
    await expect(setup.strategyFacet.connect(setup.user).updateStrategy(2, param)).to.be.reverted;
    parameters._btdType = 0;
    parameters._btdValue = "0";
    param.btdValue = "0";
    parameters._buyTwapTime = 2;
    parameters._buyTwapTimeUnit = 1;
    param.buyTwapTime = 1;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.strategyFacet.connect(setup.user).updateStrategy(3, param);
    let strategy = await setup.strategyFacet.getStrategy(3);
    expect(strategy.parameters._buyTwapTime).to.equal(1);
    param.toggleCancelOnFloor = true;
    param.toggleCompleteOnSell = true;
    param.toggleLiquidateOnFloor = true;
    await setup.strategyFacet.connect(setup.user).updateStrategy(3, param);
    strategy = await setup.strategyFacet.getStrategy(3);
    expect(strategy.parameters._cancelOnFloor).to.equal(true);
    expect(strategy.parameters._liquidateOnFloor).to.equal(true);
    expect(strategy.parameters._completeOnSell).to.equal(true);
  });
});
