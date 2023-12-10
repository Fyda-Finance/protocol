import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

import deployDiamond from "../../scripts/deploy";
import {
  BuyFacet,
  FloorFacet,
  LensFacet,
  ScenarioDEX,
  ScenarioERC20,
  ScenarioFeedAggregator,
  SellFacet,
  StrategyFacet,
} from "../../typechain-types";

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
  lensFacet: LensFacet;
};

export type Parameters = {
  _investToken: string;
  _stableToken: string;
  _stableAmount: string;
  _investAmount: string;
  _impact: number;
  _floorType: number;
  _floorValue: string;
  _liquidateOnFloor: boolean;
  _cancelOnFloor: boolean;
  _buyType: number;
  _buyValue: string;
  _buyTwapTime: number;
  _buyTwapTimeUnit: number;
  _btdValue: string;
  _btdType: number;
  _buyDCAUnit: number;
  _buyDCAValue: string;
  _sellType: number;
  _sellValue: string;
  _highSellValue: string;
  _strValue: string;
  _strType: number;
  _sellDCAUnit: number;
  _sellDCAValue: string;
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
  const scenarioERC20WETH = await scenarioERC20.deploy("WETH", "WETH", 18);
  await scenarioERC20USDC.mint(user.address, ethers.utils.parseUnits("20000000000", 6));
  await scenarioERC20WETH.mint(user.address, ethers.utils.parseUnits("20000000000000000000000", 18));

  const strategyFacet = await ethers.getContractAt("StrategyFacet", diamondAddress);
  const lensFacet = await ethers.getContractAt("LensFacet", diamondAddress);
  const buyFacet = await ethers.getContractAt("BuyFacet", diamondAddress);
  const sellFacet = await ethers.getContractAt("SellFacet", diamondAddress);
  const floorFacet = await ethers.getContractAt("FloorFacet", diamondAddress);

  const priceOracleFacet = await ethers.getContractAt("PriceOracleFacet", diamondAddress);
  await priceOracleFacet.setMaxStalePricePeriod("1000000000000000");

  const ScenarioFeedAggregator = await ethers.getContractFactory("ScenarioFeedAggregator");
  const usdcScenarioFeedAggregator: ScenarioFeedAggregator = await ScenarioFeedAggregator.deploy();
  const wethScenarioFeedAggregator: ScenarioFeedAggregator = await ScenarioFeedAggregator.deploy();

  await priceOracleFacet.setAssetFeed(scenarioERC20USDC.address, usdcScenarioFeedAggregator.address);
  await priceOracleFacet.setAssetFeed(scenarioERC20WETH.address, wethScenarioFeedAggregator.address);

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
    lensFacet,
  };
}

export type Permit = {
  tokenOwner: string;
  tokenReceiver: string;
  value: string;
  deadline: string;
  v: number;
  r: string;
  s: string;
};

export async function getPermit(
  tokenOwner: SignerWithAddress,
  tokenReceiver: string,
  nonce: number,
  chainId: number,
  tokenName: string,
  tokenAddress: string,
): Promise<Permit> {
  const domain = {
    name: tokenName,
    version: "1",
    chainId: chainId,
    verifyingContract: tokenAddress,
  };

  const types = {
    Permit: [
      {
        name: "owner",
        type: "address",
      },
      {
        name: "spender",
        type: "address",
      },
      {
        name: "value",
        type: "uint256",
      },
      {
        name: "nonce",
        type: "uint256",
      },
      {
        name: "deadline",
        type: "uint256",
      },
    ],
  };

  const value = ethers.constants.MaxUint256;
  const deadline = ethers.constants.MaxUint256;

  // set the Permit type values
  const values = {
    owner: tokenOwner.address,
    spender: tokenReceiver,
    value: value,
    nonce: nonce,
    deadline: deadline,
  };

  const signature = await tokenOwner._signTypedData(domain, types, values);
  const sig = ethers.utils.splitSignature(signature);

  return {
    tokenOwner: tokenOwner.address,
    tokenReceiver: tokenReceiver,
    value: value.toString(),
    deadline: deadline.toString(),
    v: sig.v,
    r: sig.r,
    s: sig.s,
  };
}
