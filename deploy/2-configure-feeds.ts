import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { PriceOracleFacet } from "../typechain-types";

const feeds: any = {
  goerli: [
    {
      token: "0x3e6fFe1Dd604C3315Ce48eb9cf1121A3062768D5",
      feed: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7",
    },
    {
      token: "0x8FD6903611C717BC8673dd890eC5902551C15D82",
      feed: "0x48731cF7e84dc94C5f84577882c14Be11a5B7456",
    },
    {
      token: "0x21B903707b559BC0DF7b21412bEb4cBff2d4d133",
      feed: "0xA39434A63A52E749F02807ae27335515BA4b07F7",
    },
    {
      token: "0xA6FDe5C7fC7ec36eBC7e389329354CCf6dfab94F",
      feed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    },
  ],
};

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const diamond = await hre.ethers.getContract("Diamond");
  const priceOracleFacet: PriceOracleFacet = await ethers.getContractAt("PriceOracleFacet", diamond.address);
  const networkFeeds = feeds[network.name];

  for (let i = 0; i < networkFeeds.length; i++) {
    const feed = networkFeeds[i];
    console.log("Configuring feed for token", feed.token, feed.feed);
    let tx = await priceOracleFacet.setAssetFeed(feed.token, feed.feed);
    await tx.wait();
  }

  console.log("Configuration complete");
};

module.exports.tags = ["configureFeeds"];
