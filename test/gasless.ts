import { ethers } from "ethers";

import { Parameters, Permit, SetupDiamondFixture, getPermit, setupDiamondFixture } from "./utils";

const { expect } = require("chai");

describe("Gasless", function () {
  let setup: SetupDiamondFixture; // Adjust the type as needed

  beforeEach(async function () {
    setup = await setupDiamondFixture();
  });

  it("gasless buy", async () => {
    const budget = "1000000000"; // $1k

    await setup.scenarioERC20USDC.connect(setup.user).approve(setup.strategyFacet.address, budget);

    const parameters = {
      _investToken: setup.scenarioERC20WETH.address,
      _stableToken: setup.scenarioERC20USDC.address,
      _stableAmount: budget,
      _investAmount: "0",
      _slippage: 1000,
      _floor: true,
      _floorType: 1,
      _floorValue: "1000000000",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: true,
      _buyType: 1,
      _buyValue: "1500000000",
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
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

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");

    //sign strategy
    const messageHash = await setup.strategyFacet.getMessageHash(
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

  it("gasless and permit buy", async () => {
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
      _slippage: 1000,
      _floor: true,
      _floorType: 1,
      _floorValue: "1000000000",
      _liquidateOnFloor: false,
      _cancelOnFloor: false,
      _buy: true,
      _buyType: 1,
      _buyValue: "1500000000",
      _buyTwap: false,
      _buyTwapTime: 0,
      _buyTwapTimeUnit: 0,
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

    // 1 WETH = 1200 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20WETH.address, "120000000000");

    // 1 USDC = 1 USD
    await setup.scenarioDEX.updateExchangeRate(setup.scenarioERC20USDC.address, "100000000");

    //sign strategy
    const messageHash = await setup.strategyFacet.getMessageHash(
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
});
