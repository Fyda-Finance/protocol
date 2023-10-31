import { SetupDiamondFixture, setupDiamondFixture } from "./utils";

const { expect } = require("chai");

describe("Your Test Suite", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed

  beforeEach(async function () {
    setup = await setupDiamondFixture();
  });

  // Your test cases go here
  // it("Buy the dip", async () => {
  //   const budget = "1000000000"; // $1k

  //   await setup.scenarioERC20USDC
  //     .connect(setup.user)
  //     .approve(setup.strategyFacet.address, budget);

  //   const parameters = {
  //     _investToken: setup.scenarioERC20WETH.address,
  //     _stableToken: setup.scenarioERC20USDC.address,
  //     _stableAmount: budget,
  //     _investAmount: "0",
  //     _slippage: 1000,
  //     _floor: false,
  //     _floorType: 0,
  //     _floorValue: "0",
  //     _liquidateOnFloor: false,
  //     _cancelOnFloor: false,
  //     _buy: true,
  //     _buyType: 1,
  //     _buyValue: "1500000000",
  //     _buyTwap: false,
  //     _buyTwapTime: 0,
  //     _buyTwapTimeUnit: 0,
  //     _btd: true,
  //     _btdValue: "50000000",
  //     _btdType: 3,
  //     _buyDCAUnit: 2,
  //     _buyDCAValue: "100000000",
  //     _sell: false,
  //     _sellType: 0,
  //     _sellValue: "0",
  //     _highSellValue: 0,
  //     _str: false,
  //     _strValue: 0,
  //     _strType: 0,
  //     _sellDCAUnit: 0,
  //     _sellDCAValue: "0",
  //     _sellTwap: false,
  //     _sellTwapTime: 0,
  //     _sellTwapTimeUnit: 0,
  //     _completeOnSell: false,
  //     _current_price: 0,
  //   };

  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

  //   await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000050");
  //   await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
  //   await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000100");
  //   await setup.wethScenarioFeedAggregator.setRoundPrice(12, "120000000100");

  //   // 1 WETH = 1200 USD
  //   await setup.scenarioDEX.updateExchangeRate(
  //     setup.scenarioERC20WETH.address,
  //     "120000000000"
  //   );

  //   // 1 USDC = 1 USD
  //   await setup.scenarioDEX.updateExchangeRate(
  //     setup.scenarioERC20USDC.address,
  //     "100000000"
  //   );
  //   await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

  //   const value = await setup.buyFacet.executionBuyValue(0);

  //   const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
  //     setup.scenarioERC20USDC.address,
  //     setup.scenarioERC20WETH.address,
  //     value,
  //   ]);

  //   await expect(
  //     setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
  //       dex: setup.scenarioDEX.address,
  //       callData: dexCalldata,
  //     })
  //   ).to.be.reverted;

  //   await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000000");
  //   await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
  //   await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000000");
  //   await setup.wethScenarioFeedAggregator.setRoundPrice(12, "125000000000");
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
  //   await setup.buyFacet.connect(setup.user).executeBTD(0, 10, 10, 12, 12, {
  //     dex: setup.scenarioDEX.address,
  //     callData: dexCalldata,
  //   });
  //   parameters._btdValue = "500";
  //   parameters._btdType = 2;
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
  //   await setup.strategyFacet.connect(setup.user).createStrategy(parameters);

  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
  //   await expect(
  //     setup.buyFacet.connect(setup.user).executeBTD(1, 10, 10, 12, 12, {
  //       dex: setup.scenarioDEX.address,
  //       callData: dexCalldata,
  //     })
  //   ).to.be.reverted;
  //   await setup.wethScenarioFeedAggregator.setRoundPrice(12, "127000000000");
  //   await setup.buyFacet.connect(setup.user).executeBTD(1, 10, 10, 12, 12, {
  //     dex: setup.scenarioDEX.address,
  //     callData: dexCalldata,
  //   });
  //   parameters._buyDCAUnit = 1;
  //   parameters._buyDCAValue = "900";
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
  //   await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
  //   await setup.buyFacet.connect(setup.user).executeBTD(2, 10, 10, 12, 12, {
  //     dex: setup.scenarioDEX.address,
  //     callData: dexCalldata,
  //   });
  //   parameters._buyValue = "1100000000";
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
  //   await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
  //   await expect(
  //     setup.buyFacet.connect(setup.user).executeBTD(3, 10, 10, 12, 12, {
  //       dex: setup.scenarioDEX.address,
  //       callData: dexCalldata,
  //     })
  //   ).to.be.reverted;
  //   parameters._current_price = 1;
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);
  //   await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
  //   await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);
  //   await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);
  //   await setup.buyFacet.connect(setup.user).executeBTD(4, 10, 10, 12, 12, {
  //     dex: setup.scenarioDEX.address,
  //     callData: dexCalldata,
  //   });
  // });
  it("Buy twap", async () => {
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
      _buyTwap: true,
      _buyTwapTime: 1,
      _buyTwapTimeUnit: 1,
      _btd: false,
      _btdValue: 0,
      _btdType: 0,
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

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    await setup.usdcScenarioFeedAggregator.setRoundPrice(10, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(10, "120000000000");
    await setup.usdcScenarioFeedAggregator.setRoundPrice(12, "100000000");
    await setup.wethScenarioFeedAggregator.setRoundPrice(12, "120000000000");

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

    await setup.buyFacet.connect(setup.user).executeBuyTwap(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    await expect(
      setup.buyFacet.connect(setup.user).executeBuyTwap(0, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      })
    ).to.be.reverted;
  });
});
