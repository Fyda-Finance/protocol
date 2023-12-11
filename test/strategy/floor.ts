import { ParamType } from "ethers/lib/utils";

import { Parameters, SetupDiamondFixture, setupDiamondFixture } from "../utils";

const { expect } = require("chai");

describe("Floor", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed
  const budget = "1000000000000000000000"; // $1k
  let parameters: any;

  beforeEach(async function () {
    setup = await setupDiamondFixture();

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
      _current_price_buy: 0,
      _current_price_sell: 0,
      _minimumLoss: 0,
      _minimumProfit: 0,
    };
  });

  it("floor", async () => {
    await setup.scenarioERC20WETH.connect(setup.user).approve(setup.strategyFacet.address, budget);

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");
    parameters._floorType = 2;
    parameters._floorValue = "1000";
    parameters._investAmount = "1000000000000000000000";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters, 0);

    const dexCalldata = setup.scenarioDEX.interface.encodeFunctionData("swap", [
      setup.scenarioERC20WETH.address,
      setup.scenarioERC20USDC.address,
      parameters._investAmount,
    ]);

    await setup.wethScenarioFeedAggregator.setPrice("100000000000", 5);

    await setup.floorFacet.connect(setup.user).executeFloor(0, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });

    parameters._cancelOnFloor = true;
    parameters._liquidateOnFloor = true;
    parameters._floorType = 1;
    parameters._floorValue = "90000000000";
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters, 0);

    await setup.floorFacet.connect(setup.user).executeFloor(1, {
      dex: setup.scenarioDEX.address,
      callData: dexCalldata,
    });
    await expect(
      setup.floorFacet.connect(setup.user).executeFloor(1, {
        dex: setup.scenarioDEX.address,
        callData: dexCalldata,
      }),
    ).to.be.reverted;
  });
});
