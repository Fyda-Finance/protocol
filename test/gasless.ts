import { ethers } from "ethers";

import { Parameters, Permit, SetupDiamondFixture, getPermit, setupDiamondFixture } from "./utils";

const { expect } = require("chai");

describe("Gasless", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed

  beforeEach(async function () {
    setup = await setupDiamondFixture();
  });

  it("buy", async () => {
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
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");

    //sign strategy
    const messageHash = await setup.strategyFacet.getMessageHashToCreate(
      parameters,
      await setup.lensFacet.getNonce(setup.user.address),
      setup.user.address,
    );

    const messageHashBinary = ethers.utils.arrayify(messageHash);
    const signature = await setup.user.signMessage(messageHashBinary);

    await setup.strategyFacet.createStrategyOnBehalf(
      [],
      parameters,
      setup.user.address,
      await setup.lensFacet.getNonce(setup.user.address),
      signature,
    );

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

  it("permit buy", async () => {
    const budget = "1000000000"; // $1k

    // await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);
    const permit: Permit = await getPermit(
      setup.user,
      setup.strategyFacet.address,
      (await setup.scenarioERC20USDC.nonces(setup.user.address)).toNumber(),
      (await setup.lensFacet.getChainId()).toNumber(),
      await setup.scenarioERC20USDC.name(),
      setup.scenarioERC20USDC.address,
    );

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
    };

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 5);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 5);

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");

    //sign strategy
    const messageHash = await setup.strategyFacet.getMessageHashToCreate(
      parameters,
      await setup.lensFacet.getNonce(setup.user.address),
      setup.user.address,
    );

    const messageHashBinary = ethers.utils.arrayify(messageHash);
    const signature = await setup.user.signMessage(messageHashBinary);

    await setup.strategyFacet.createStrategyOnBehalf(
      [
        {
          token: setup.scenarioERC20USDC.address,
          owner: permit.tokenOwner,
          spender: permit.tokenReceiver,
          value: permit.value,
          deadline: permit.deadline,
          v: permit.v,
          r: permit.r,
          s: permit.s,
        },
      ],
      parameters,
      setup.user.address,
      await setup.lensFacet.getNonce(setup.user.address),
      signature,
    );

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

  it("cancel", async () => {
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

    await expect(setup.strategyFacet.cancelStrategy(0)).to.be.reverted;

    const hash = await setup.strategyFacet.getMessageHashToCancel(
      0,
      await setup.lensFacet.getNonce(setup.user.address),
      setup.user.address,
    );
    const messageHashBinary = ethers.utils.arrayify(hash);
    const signature = await setup.user.signMessage(messageHashBinary);

    await setup.strategyFacet.cancelStrategyOnBehalf(
      0,
      await setup.lensFacet.getNonce(setup.user.address),
      signature,
      setup.user.address,
    );
  });

  it("update", async () => {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    await setup.wethScenarioFeedAggregator.setPrice("120000000000", 25);

    await setup.usdcScenarioFeedAggregator.setPrice("100000000", 25);

    const parameters: Parameters = {
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
    parameters._buyType = 1;
    parameters._buyValue = "1500000000";
    parameters._stableAmount = budget;
    await setup.strategyFacet.connect(setup.user).createStrategy(parameters);
    const param = {
      sellValue: "0",
      buyValue: "1400000000",
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
      current_price: 0,
    };

    const hash = await setup.strategyFacet.getMessageHashToUpdate(
      0,
      param,
      await setup.lensFacet.getNonce(setup.user.address),
      setup.user.address,
    );

    const messageHashBinary = ethers.utils.arrayify(hash);
    const signature = await setup.user.signMessage(messageHashBinary);

    await setup.strategyFacet.updateStrategyOnBehalf(
      0,
      param,
      setup.user.address,
      await setup.lensFacet.getNonce(setup.user.address),
      signature,
    );

    const strategy = await setup.strategyFacet.getStrategy(0);
    expect(strategy.parameters._buyValue).to.be.equal("1400000000");
  });
});
