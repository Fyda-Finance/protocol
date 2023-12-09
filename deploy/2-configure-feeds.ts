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
  arbitrum: [
    {
      // LINK
      token: "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
      feed: "0x86e53cf1b870786351da77a57575e79cb55812cb",
    },
    {
      // WETH
      token: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      feed: "0x639fe6ab55c921f74e7fac1ee960c0b6293ba612",
    },
    {
      // WBTC
      token: "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
      feed: "0xd0c7101eacbb49f3decccc166d238410d6d46d57",
    },
    {
      // UNI
      token: "0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0",
      feed: "0x9c917083fdb403ab5adbec26ee294f6ecada2720",
    },
    {
      // USDT
      token: "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
      feed: "0x3f3f5df88dc9f13eac63df89ec16ef6e7e25dde7",
    },
    {
      // USDC
      token: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
      feed: "0x50834f3163758fcc1df9973b6e91f0f0f0434ad3",
    },
    {
      // DAI
      token: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
      feed: "0xc5c8e77b397e531b8ec06bfb0048328b30e9ecfb",
    },
    {
      // SUSHI
      token: "0xd4d42F0b6DEF4CE0383636770eF773390d85c61A",
      feed: "0xb2a8ba74cbca38508ba1632761b56c897060147c",
    },
    {
      // SPELL
      token: "0x3E6648C5a70A150A88bCE65F4aD4d506Fe15d2AF",
      feed: "0x383b3624478124697bef675f07ca37570b73992f",
    },
    {
      // DPX
      token: "0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55",
      feed: "0xc373b9db0707fd451bc56ba5e9b029ba26629df0",
    },
    {
      // COMP
      token: "0x354A6dA3fcde098F8389cad84b0182725c6C91dE",
      feed: "0xe7c53ffd03eb6cef7d208bc4c13446c76d1e5884",
    },
    {
      // BAL
      token: "0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8",
      feed: "0xbe5ea816870d11239c543f84b71439511d70b94f",
    },
    {
      // KNC
      token: "0xe4DDDfe67E7164b0FE14E218d80dC4C08eDC01cB",
      feed: "0xbf539d4c2106dd4d9ab6d56aed3d9023529db145",
    },
    {
      // ARB
      token: "0x912CE59144191C1204E64559FE8253a0e49E6548",
      feed: "0xb2a824043730fe05f3da2efafa1cbbe83fa548d6",
    },
    {
      // CRV
      token: "0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978",
      feed: "0xaebda2c976cfd1ee1977eac079b4382acb849325",
    },
    {
      // GMX
      token: "0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a",
      feed: "0xdb98056fecfff59d032ab628337a4887110df3db",
    },
    {
      // GNS
      token: "0x18c11FD286C5EC11c3b683Caa813B77f5163A122",
      feed: "0xe89e98ce4e19071e59ed4780e0598b541ce76486",
    },
    {
      // JOE
      token: "0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07",
      feed: "0x04180965a782e487d0632013aba488a472243542",
    },
    {
      // LDO
      token: "0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60",
      feed: "0xa43a34030088e6510feccfb77e88ee5e7ed0fe64",
    },
    {
      // LUSD
      token: "0x93b346b6BC2548dA6A1E7d98E9a421B42541425b",
      feed: "0x0411d28c94d85a36bc72cb0f875dfa8371d8ffff",
    },
    {
      // RDNT
      token: "0x0411d28c94d85a36bc72cb0f875dfa8371d8ffff",
      feed: "0x20d0fcab0ecfd078b036b6caf1fac69a6453b352",
    },
    {
      // RPL
      token: "0xB766039cc6DB368759C1E56B79AFfE831d0Cc507",
      feed: "0xf0b7159bbfc341cc41e7cb182216f62c6d40533d",
    },
    {
      // STG
      token: "0x6694340fc020c5E6B96567843da2df01b2CE1eb6",
      feed: "0xe74d69e233fab0d8f48921f2d93adfde44ceb3b7",
    },
    {
      // FRAX
      token: "0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F",
      feed: "0x0809e3d38d1b4214958faf06d8b1b1a2b73f2ab8",
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
