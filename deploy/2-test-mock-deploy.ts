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

  console.log("Fetching strategy Facets");
  const strategyFacet: StrategyFacet = await ethers.getContractAt("StrategyFacet", addresses[network.name].diamond);
  const sellFacet: SellFacet = await ethers.getContractAt("SellFacet", addresses[network.name].diamond, accounts[1]);
  console.log((await sellFacet.executionSellAmount(true, 7)).toString());
  const executeSell = await sellFacet.callStatic.executeSTR(
    7,
    "18446744073709552204",
    "18446744073709570418",
    "18446744073709552204",
    "18446744073709570419",
    {
      dex: "0x101E628cbC91c6b0c6348bde885a125C29A9229E",
      callData:
        "0xdf791e500000000000000000000000003e6ffe1dd604c3315ce48eb9cf1121a3062768d50000000000000000000000008fd6903611c717bc8673dd890ec5902551c15d8200000000000000000000000000000000000000000000000000000000000f4240",
    },
  );
  await executeSell.wait();

  // console.log("Succefully connected with contracts");
};

module.exports.tags = ["testMock"];
