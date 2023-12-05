import { ethers } from "hardhat";
import hre from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import deployDiamond from "../scripts/deploy";
import { BuyFacet, PriceOracleFacet, ScenarioDEX, SellFacet, StrategyFacet } from "../typechain-types";

const addresses: any = {
  goerli: {
    usdc: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7",
    wbtc: "0xA39434A63A52E749F02807ae27335515BA4b07F7",
    eth: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    link: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
    diamond: "0x34d9f39f8C46Aa40930f6Ce70F82Fb702BA6f38A",
  },
};

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0].address;

  /**
   * 1. Deploy ERC20 Tokens
   * 2. Deploy DEX
   * 3. Deploy Diamond
   * 3. Configure Price for ERC20 in DEX and Diamond
   */

  console.log("Fetching strategy Facets");
  const strategyFacet: StrategyFacet = await ethers.getContractAt("StrategyFacet", addresses[network.name].diamond);
  // const sellFacet: SellFacet = await ethers.getContractAt("SellFacet", addresses[network.name].diamond);

  // const parameters = {
  //   _investToken: weth.address,
  //   _stableToken: usdc.address,
  //   _stableAmount: "100000000",
  //   _investAmount: "0",
  //   _impact: 10,
  //   _floorType: 0,
  //   _floorValue: "0",
  //   _liquidateOnFloor: false,
  //   _cancelOnFloor: false,
  //   _buyType: 1,
  //   _buyValue: "1900000000",
  //   _buyTwapTime: 0,
  //   _buyTwapTimeUnit: 0,
  //   _btdValue: "0",
  //   _btdType: 0,
  //   _buyDCAUnit: 0,
  //   _buyDCAValue: "0",
  //   _sellType: 0,
  //   _sellValue: "0",
  //   _highSellValue: "0",
  //   _strValue: "0",
  //   _strType: 0,
  //   _sellDCAUnit: 0,
  //   _sellDCAValue: "0",
  //   _sellTwapTime: 0,
  //   _sellTwapTimeUnit: 0,
  //   _completeOnSell: false,
  //   _current_price: 0,
  // };
  // const createStrategy = await strategyFacet.connect(accounts[1]).createStrategy(parameters);
  // await createStrategy.wait();
  const strategy = await strategyFacet.getStrategy(1);
  console.log("Strategy: ", strategy);
  // let value = await buyFacet.executionBuyAmount(true, 1);
  // console.log("Value: ", value);
  // let dexCalldata = dex.interface.encodeFunctionData("swap", [
  //   usdc.address,
  //   weth.address,
  //   value,
  // ]);
  // console.log("Dex call Data ", dexCalldata);
  // console.log("Dex address: ", dex.address);
  //18446744073709568035 18446744073709552205 18446744073709568037 18446744073709552205
  // const executeSell = await sellFacet
  //   .connect(accounts[0])
  //   .callStatic.executeSTR(
  //     1,
  //     "18446744073709568035",
  //     "18446744073709552205",
  //     "18446744073709568037",
  //     "18446744073709552205",
  //     {
  //       dex: "0x101E628cbC91c6b0c6348bde885a125C29A9229E",
  //       callData:
  //         "0xdf791e50000000000000000000000000a6fde5c7fc7ec36ebc7e389329354ccf6dfab94f0000000000000000000000003e6ffe1dd604c3315ce48eb9cf1121a3062768d500000000000000000000000000000000000000000000000000b1a2bc2ec50000",
  //     },
  //   );
  // // await executeSell.wait();

  // console.log("Succefully connected with contracts");
};

module.exports.tags = ["testMock"];
