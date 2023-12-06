import { Parameters, SetupDiamondFixture, setupDiamondFixture } from "../utils";

const { expect } = require("chai");

describe("Buy", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed
  let parameters: any;
  const budget = "1000000000"; // $1k

  beforeEach(async function () {
    setup = await setupDiamondFixture();

    parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: "0",
      _impact: 1000,
      _floorType: 0,
      _floorValue: "0",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buyType: 0,
      _buyValue: "0",
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btdValue: "0",
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: "0",
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
      _current_price: 0,

      _minimumProfit: 0,
    };
  });

  // Your test cases go here
  it("Buy the dip", async () => {
    // await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);
    // parameters._buyType = 1;
    // parameters._buyValue = "1500000000";
    // parameters._btdValue = "50000000";
    // parameters._btdType = 3;
    // parameters._buyDCAUnit = 2;
    // parameters._buyDCAValue = "100000000";
    // await setup.wethScenarioFeedAggregator.setPrice("120000000100", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000050");
    // await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
    // await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000100");
    // await setup.wethScenarioFeedAggregator.setRoundPrice(12, "120000000100");
    // // 1 WETH = 1200 USD
    // await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000100");
    // // 1 USDC = 1 USD
    // await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");
    // await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    // let value = await setup.buyFacet.executionBuyAmount(false, 0);
    // let dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await expect(
    //   setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
    //     dex: setup.scenarioDEX.address,
    //     callData: dexCalldata,
    //   }),
    // ).to.be.reverted;
    // await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000000");
    // await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
    // await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000000");
    // await setup.wethScenarioFeedAggregator.setRoundPrice(12, "125000000000");
    // await setup.wethScenarioFeedAggregator.setPrice("125000000000", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // value = await setup.buyFacet.executionBuyAmount(false, 0);
    // dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
    //   dex: setup.scenarioDEX.address,
    //   callData: dexCalldata,
    // });
    // parameters._btdValue = "500";
    // parameters._btdType = 2;
    // await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    // value = await setup.buyFacet.executionBuyAmount(false, 1);
    // dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await expect(
    //   setup.buyFacet.connect(setup.user).executeBTD(1, 10, 10, 12, 12, {
    //     dex: setup.scenarioDEX.address,
    //     callData: dexCalldata,
    //   }),
    // ).to.be.reverted;
    // await setup.wethScenarioFeedAggregator.setRoundPrice(12, "127000000000");
    // await setup.buyFacet.connect(setup.user).executeBTD(1, 10, 10, 12, 12, {
    //   dex: setup.scenarioDEX.address,
    //   callData: dexCalldata,
    // });
    // parameters._buyDCAUnit = 1;
    // parameters._buyDCAValue = "900";
    // await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    // value = await setup.buyFacet.executionBuyAmount(false, 2);
    // dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await setup.buyFacet.connect(setup.user).executeBTD(2, 10, 10, 12, 12, {
    //   dex: setup.scenarioDEX.address,
    //   callData: dexCalldata,
    // });
    // parameters._buyValue = "1100000000";
    // await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    // value = await setup.buyFacet.executionBuyAmount(false, 3);
    // dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await expect(
    //   setup.buyFacet.connect(setup.user).executeBTD(3, 10, 10, 12, 12, {
    //     dex: setup.scenarioDEX.address,
    //     callData: dexCalldata,
    //   }),
    // ).to.be.reverted;
    // parameters._current_price = 1;
    // await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
    // await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    // await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    // value = await setup.buyFacet.executionBuyAmount(false, 4);
    // dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
    //   setup.scenarioERC20USDC.address,
    //   setup.scenarioERC20WETH.address,
    //   value,
    // ]);
    // await setup.buyFacet.connect(setup.user).executeBTD(4, 10, 10, 12, 12, {
    //   dex: setup.scenarioDEX.address,
    //   callData: dexCalldata,
    // });
  });
  it("Buy twap", async () => {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    parameters._buyType = 1;
    parameters._buyValue = "1500000000";
    parameters._buyTwapTime = 1;
    parameters._buyTwapTimeUnit = 1;
    parameters._buyDCAUnit = 2;
    parameters._buyDCAValue = "100000000";

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
    await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "120000000000");

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const value = await setup.buyFacet.executionBuyAmount(false, 0);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      value,
    ]);

    await setup.buyFacet.connect(setup.user).executeBuyTwap(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    await expect(
      setup.buyFacet.connect(setup.user).executeBuyTwap(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      }),
    ).to.be.reverted;
  });

  it("simple buy", async () => {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    const parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: "0",
      _impact: 1000,
      _floorType: 1,
      _floorValue: "1000000000",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buyType: 1,
      _buyValue: "1500000000",
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btdValue: 0,
      _btdType: 0,
      _buyDCAUnit: 2,
      _buyDCAValue: "100000000",
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
      _current_price: 0,

      _minimumProfit: 0,
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const value = await setup.buyFacet.executionBuyAmount(true, 0);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20USDC.address,
      setup.scenarioERC20WETH.address,
      value,
    ]);
    await setup.wethScenarioFeedAggregator.setPrice("90000000000", 5);

    await expect(
      setup.buyFacet.connect(setup.user).executeBuy(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      }),
    ).to.be.reverted;

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
    await setup.buyFacet.connect(setup.user).executeBuy(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    await expect(
      setup.buyFacet.connect(setup.user).executeBuy(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      }),
    ).to.be.reverted;
  });
});
