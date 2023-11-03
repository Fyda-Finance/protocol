import deployDiamond from "../../scripts/deploy";
import {
  BuyFacet,
  FloorFacet,
  ScenarioDEX,
  ScenarioERC20,
  ScenarioFeedAggregator,
  SellFacet,
  StrategyFacet,
} from "../../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

export type SetupDiamondFixture = {
  scenarioERC20USDC: ScenarioERC20;
  scenarioERC20WETH: ScenarioERC20;
  scenarioDEX: ScenarioDEX;
  strategyFacet: StrategyFacet;
  buyFacet: BuyFacet;
  sellFacet: SellFacet;
  floorFacet: FloorFacet;
  owner: SignerWithAddress;
  user: SignerWithAddress;
  usdcScenarioFeedAggregator: ScenarioFeedAggregator;
  wethScenarioFeedAggregator: ScenarioFeedAggregator;
};

export type Parameters = {
  _investToken: string;
  _stableToken: string;
  _stableAmount: string;
  _investAmount: string;
  _slippage: number;
  _floor: boolean;
  _floorType: number;
  _floorValue: string;
  _liquidateOnFloor: boolean;
  _cancelOnFloor: boolean;
  _buy: boolean;
  _buyType: number;
  _buyValue: string;
  _buyTwap: boolean;
  _buyTwapTime: number;
  _buyTwapTimeUnit: number;
  _btd: boolean;
  _btdValue: string;
  _btdType: number;
  _buyDCAUnit: number;
  _buyDCAValue: string;
  _sell: boolean;
  _sellType: number;
  _sellValue: string;
  _highSellValue: string;
  _str: boolean;
  _strValue: string;
  _strType: number;
  _sellDCAUnit: number;
  _sellDCAValue: string;
  _sellTwap: boolean;
  _sellTwapTime: number;
  _sellTwapTimeUnit: number;
  _completeOnSell: boolean;
  _current_price: number;
};

export async function setupDiamondFixture(): Promise<SetupDiamondFixture> {
  const [owner, user] = await ethers.getSigners();

  const diamondAddress = await deployDiamond(owner);

  const ScenarioDEX = await ethers.getContractFactory("ScenarioDEX");
  const scenarioDEX = await ScenarioDEX.deploy();

  const scenarioERC20 = await ethers.getContractFactory("ScenarioERC20");
  const scenarioERC20USDC = await scenarioERC20.deploy("USDC", "USDC", 6);
  console.log("USDC Address: ", scenarioERC20USDC.address);
  const scenarioERC20WETH = await scenarioERC20.deploy("WETH", "WETH", 18);
  console.log("WETH Address: ", scenarioERC20WETH.address);
  await scenarioERC20USDC.mint(
    user.address,
    ethers.utils.parseUnits("20000000000", 6)
  );
  await scenarioERC20WETH.mint(
    user.address,
    ethers.utils.parseUnits("20000000000000000000000", 18)
  );

  const strategyFacet = await ethers.getContractAt(
    "StrategyFacet",
    diamondAddress
  );
  const buyFacet = await ethers.getContractAt("BuyFacet", diamondAddress);
  const sellFacet = await ethers.getContractAt("SellFacet", diamondAddress);
  const floorFacet = await ethers.getContractAt("FloorFacet", diamondAddress);

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
    sellFacet,
    floorFacet,
    owner,
    user,
    usdcScenarioFeedAggregator,
    wethScenarioFeedAggregator,
  };
}
