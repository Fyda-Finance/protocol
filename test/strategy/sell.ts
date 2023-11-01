import { SetupDiamondFixture, setupDiamondFixture } from "./utils";

const { expect } = require("chai");

describe("sell Tests", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed
  const budget = "1000000000000000000000"; // $1k
  let parameters;

  beforeEach(async function () {
    setup = await setupDiamondFixture();

    parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: "0",
      _investAmount: "0",
      _slippage: 1000,
      _floor: false,
      _floorType: 0,
      _floorValue: "0",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: false,
      _buyType: 0,
      _buyValue: "0",
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
      _btd: false,
      _btdValue: "0",
      _btdType: 0,
      _buyDCAUnit: 0,
      _buyDCAValue: "0",
      _sell: false,
      _sellType: 0,
      _sellValue: "0",
      _highSellValue: "0",
      _str: false,
      _strValue: "0",
      _strType: 0,
      _sellDCAUnit: 0,
      _sellDCAValue: "0",
      _sellTwap: false,
      _sellTwapTime: 0,
      _sellTwapTimeUnit: 0,
      _completeOnSell: false,
      _current_price: 0,
    };
  });

  // Your test cases go here
  it("sell the rally", async () => {
    await setup.scenarioERC20WETH
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 5);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(10, "160000000000");
    await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "160000000100");
    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20WETH.address,
      "160000000000"
    );
    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(
      setup.scenarioERC20USDC.address,
      "100000000"
    );
    parameters._sell = true;
    parameters._sellType = 1;
    parameters._sellValue = "1500000000";
    parameters._investAmount = "1000000000000000000000";
    parameters._sellDCAUnit = 2;
    parameters._sellDCAValue = "100000000000000000000";
    parameters._str = true;
    parameters._strValue = "100000000";
    parameters._strType = 3;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    let value = await setup.sellFacet.executionSellValue(false, 0);
    let dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      value,
    ]);
    console.log("Executing first");
    await expect(
      setup.sellFacet.connect(setup.user).executeSTR(0, 10, 10, 12, 12, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
    await setup.wethScenarioFeedAggregator.setRoundPrice(10, "160000000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "175000000000");
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 25);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    console.log("Executing second");
    await setup.sellFacet.connect(setup.user).executeSTR(0, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
    parameters._strValue = "900";
    parameters._strType = 2;
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 5);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "165000000000");

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 25);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    value = await setup.sellFacet.executionSellValue(false, 1);
    dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      value,
    ]);
    console.log("Executing third");
    await expect(
      setup.sellFacet.connect(setup.user).executeSTR(1, 10, 10, 12, 12, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "1750000000000");
    console.log("Executing fourth");
    await setup.sellFacet.connect(setup.user).executeSTR(1, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
    parameters._sellDCAUnit = 1;
    parameters._sellDCAValue = "900";
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 5);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 25);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    console.log("Executing fifth");
    await setup.sellFacet.connect(setup.user).executeSTR(2, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
    parameters._sellValue = "11000000000";
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 5);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 25);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    console.log("Executing sixth");
    await expect(
      setup.sellFacet.connect(setup.user).executeSTR(3, 10, 10, 12, 12, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
    parameters._current_price = 2;
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 5);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    await setup.wethScenarioFeedAggregator.setPrice("160000000000", 25);
    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
    console.log("Executing seventh");
    await setup.sellFacet.connect(setup.user).executeSTR(4, 10, 10, 12, 12, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
  });
  it("sell twap", async () => {
    await setup.scenarioERC20WETH
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

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
    parameters._sell = true;
    parameters._sellType = 1;
    parameters._sellValue = "1200000000";
    parameters._investAmount = "1000000000000000000000";
    parameters._sellDCAUnit = 2;
    parameters._sellDCAValue = "100000000000000000000";
    parameters._sellTwap = true;
    parameters._sellTwapTime = 1;
    parameters._sellTwapTimeUnit = 1;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const value = await setup.sellFacet.executionSellValue(false, 0);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      value,
    ]);

    await setup.sellFacet.connect(setup.user).executeSellTwap(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    await expect(
      setup.sellFacet.connect(setup.user).executeSellTwap(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
  });

  it("simple sell", async () => {
    await setup.scenarioERC20WETH
      .connect(setup.user)
      .approve(setup.strategyFacet.address, budget);

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

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
    parameters._sell = true;
    parameters._sellType = 1;
    parameters._sellValue = "1200000000";
    parameters._investAmount = "1000000000000000000000";

    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

    const value = await setup.sellFacet.executionSellValue(true, 0);
    console.log("Value: ", value);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      value,
    ]);

    await setup.sellFacet.connect(setup.user).executeSell(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    await expect(
      setup.sellFacet.connect(setup.user).executeSell(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
  });
});
