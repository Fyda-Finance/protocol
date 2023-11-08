import {
  PriceOracleFacet,
  ScenarioDEX,
  StrategyFacet,
  BuyFacet,
} from "../typechain-types";
import { ethers } from "hardhat";
import hre from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const addresses: any = {
  goerli: {
    usdc: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7",
    wbtc: "0xA39434A63A52E749F02807ae27335515BA4b07F7",
    eth: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    link: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
    diamond: "0x29894a2F6f9FA2F3E0Be08465Af2Ca572d962687",
  },
};

module.exports = async ({
  network,
  getNamedAccounts,
  deployments,
}: HardhatRuntimeEnvironment) => {
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
  const strategyFacet: StrategyFacet = await ethers.getContractAt(
    "StrategyFacet",
    addresses[network.name].diamond
  );
  const buyFacet: BuyFacet = await ethers.getContractAt(
    "BuyFacet",
    addresses[network.name].diamond
  );
  const parameters = {
    _investToken: weth.address,
    _stableToken: usdc.address,
    _stableAmount: "100000000",
    _investAmount: "0",
    _slippage: 10,
    _floor: false,
    _floorType: 0,
    _floorValue: "0",
    _liquidateOnFloor: false,
    _cancelOnFloor: false,
    _buy: true,
    _buyType: 1,
    _buyValue: "1900000000",
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
  const createStrategy = await strategyFacet
    .connect(accounts[1])
    .createStrategy(parameters);
  await createStrategy.wait();
  const strategy = await strategyFacet.getStrategy(1);
  console.log("Strategy: ", strategy);
  let value = await buyFacet.executionBuyAmount(true, 1);
  console.log("Value: ", value);
  let dexCalldata = dex.interface.encodeFunctionData("swap", [
    usdc.address,
    weth.address,
    value,
  ]);
  console.log("Dex call Data ", dexCalldata);
  console.log("Dex address: ", dex.address);
  const executeBuy = await buyFacet
    .connect(accounts[1])
    .executeBuy(1, { dex: dex.address, callData: dexCalldata });
  await executeBuy.wait();

  console.log("Succefully connected with contracts");
};

module.exports.tags = ["testMock"];
