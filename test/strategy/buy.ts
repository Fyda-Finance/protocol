import { setupDiamondFixture, SetupDiamondFixture } from "./utils";
import { ethers } from "hardhat";

const { expect } = require("chai");

describe("Your Test Suite", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed

  beforeEach(async function () {
    setup = await setupDiamondFixture();
  });

  // Your test cases go here
  it("Buy the dip", async () => {
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
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btd: true,
      _btdValue: "50000000",
      _btdType: 3,
      _buyDCAUnit: 2,
      _buyDCAValue: "100000000",
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
      _current_price: 0,
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000");

    await setup.usdcScenarioFeedAggregator.setPrice("100000000");

    await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000050");
    await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
    await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000100");
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "120000000100");

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
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const value = await setup.buyFacet.executionBuyValue(0);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      value,
    ]);

    await setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
    await setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
  });
});
