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
    diamond: "0x8E215C804cf2a77D1230c1A9f5faF7CdbEeb10C8",
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

  const usdc = await hre.ethers.getContract("USDC");
  const wbtc = await hre.ethers.getContract("WBTC");
  const weth = await hre.ethers.getContract("WETH");
  const link = await hre.ethers.getContract("LINK");

  const dex: ScenarioDEX = await hre.ethers.getContract("MockDEX");

  // const priceOracleFacet: PriceOracleFacet = await ethers.getContractAt(
  //   "PriceOracleFacet",
  //   addresses[network.name].diamond
  // );
  // Mint USDC
  const recipientAddress = "0x7295F623794dcEE49d0B3490fF98B40B83a184Ad"; // Replace with the recipient's address
  const amountToMint = ethers.utils.parseUnits("1000", 6); // Replace with the desired amount

  // try {
  //   // Mint USDC
  //   const usdcMintTx = await usdc
  //     .connect(accounts[0])
  //     .mint(recipientAddress, amountToMint);
  //   await usdcMintTx.wait();
  //   console.log(
  //     `Minted ${ethers.utils.formatUnits(
  //       amountToMint,
  //       6
  //     )} USDC to ${recipientAddress}`
  //   );
  // } catch (error) {
  //   console.error("Error minting USDC:", error);
  // }

  const budget = "1000000000";
  // const budgetApproval = await usdc
  //   .connect(accounts[1])
  //   .approve(addresses[network.name].diamond, budget);
  // await budgetApproval.wait();
  console.log("Fetching strategy Facets");
  const strategyFacet: StrategyFacet = await ethers.getContractAt("StrategyFacet", addresses[network.name].diamond);
  const sellFacet: SellFacet = await ethers.getContractAt("SellFacet", addresses[network.name].diamond);

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
  const strategy = await strategyFacet.getStrategy(9);
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
  // const executeSell = await sellFacet
  //   .connect(accounts[0])
  //   .executeSTR(7, "18446744073709552204", "18446744073709570418", "18446744073709552204", "18446744073709570419", {
  //     dex: "0x101E628cbC91c6b0c6348bde885a125C29A9229E",
  //     callData:
  //       "0xdf791e500000000000000000000000003e6ffe1dd604c3315ce48eb9cf1121a3062768d50000000000000000000000008fd6903611c717bc8673dd890ec5902551c15d8200000000000000000000000000000000000000000000000000000000000f4240",
  //   });
  // await executeSell.wait();

  // console.log("Succefully connected with contracts");
};

module.exports.tags = ["testMock"];
