import hre from "hardhat";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { PriceOracleFacet } from "../typechain-types";

const feeds: any = {
  sepolia: [
    {
      // WBTC
      token: "0x083f66c24cDc0140a910600a020b669B2960fc7e",
      feed: "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43",
    },
    {
      // WETH
      token: "0x46eFed5564eD0FB6840abA7E8a4d12Da27757EB3",
      feed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    },
    {
      // LINK
      token: "0x1F28FB7151d3183764Ea1D724E567Bb8e0653d13",
      feed: "0xc59E3633BAAC79493d908e63626716e204A45EdF",
    },
    {
      // USDC
      token: "0x6458009bAC9ffd638331bC5612f22825893856C0",
      feed: "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E",
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
      token: "0x3082CC23568eA640225c2467653dB90e9250AaA0",
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
    {
      // TUSD
      token: "0x4D15a3A2286D883AF0AA1B3f21367843FAc63E07",
      feed: "0x6fabee62266da6686ee2744c6f15bb8352d2f28d",
    },
  ],
  polygon: [
    {
      // AAVE
      token: "0xD6DF932A45C0f255f85145f286eA0b292B21C90B",
      feed: "0x72484b12719e23115761d5da1646945632979bb6",
    },
    {
      // WMATIC
      token: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
      feed: "0xab594600376ec9fd91f8e885dadf0ce036862de0",
    },
    {
      // WETH
      token: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
      feed: "0xf9680d99d6c9589e2a93a78a04a279e509205945",
    },
    {
      // WBTC
      token: "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
      feed: "0xde31f8bfbd8c84b5360cfacca3539b938dd78ae6",
    },
    {
      // LINK
      token: "0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39",
      feed: "0xd9ffdb71ebe7496cc440152d43986aae0ab76665",
    },
    {
      // SNX
      token: "0x50B728D8D964fd00C2d0AAD81718b71311feF68a",
      feed: "0xbf90a5d9b6ee9019028dbfc2a9e50056d5252894",
    },
    {
      // SUSHI
      token: "0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a",
      feed: "0x49b0c695039243bbfeb8ecd054eb70061fd54aa0",
    },
    {
      // SAND
      token: "0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683",
      feed: "0x3d49406edd4d52fb7ffd25485f32e073b529c924",
    },
    {
      // UNI
      token: "0xb33EaAd8d922B1083446DC23f610c2567fB5180f",
      feed: "0xdf0fb4e4f928d2dcb76f438575fdd8682386e13c",
    },
    {
      // PAXG
      token: "0x553d3D295e0f695B9228246232eDF400ed3560B5",
      feed: "0x0f6914d8e7e1214cdb3a4c6fbf729b75c69df608",
    },
    {
      // KNC
      token: "0x1C954E8fe737F99f68Fa1CCda3e51ebDB291948C",
      feed: "0x10e5f3dfc81b3e5ef4e648c4454d04e79e1e41e2",
    },
    {
      // COMP
      token: "0x8505b9d2254A7Ae468c0E9dd10Ccea3A837aef5c",
      feed: "0x2a8758b7257102461bc958279054e372c2b1bde6",
    },
    {
      // BAL
      token: "0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3",
      feed: "0xd106b538f2a868c28ca1ec7e298c3325e0251d66",
    },
    {
      // 1inch
      token: "0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f",
      feed: "0x443c5116cdf663eb387e72c688d276e702135c87",
    },
    {
      // AVAX
      token: "0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b",
      feed: "0xe01ea2fbd8d76ee323fbed03eb9a8625ec981a10",
    },
    {
      // YFI
      token: "0xDA537104D6A5edd53c6fBba9A898708E465260b6",
      feed: "0x9d3a43c111e7b2c6601705d9fcf7a70c95b1dc55",
    },
    {
      // GNS
      token: "0xE5417Af564e4bFDA1c483642db72007871397896",
      feed: "0x9cb43aa3d036cb035a694ba0aaa91f8875b16ce1",
    },
    {
      // WOO
      token: "0x1B815d120B3eF02039Ee11dC2d33DE7aA4a8C603",
      feed: "0x6a99ec84819fb7007dd5d032068742604e755c56",
    },
    {
      // FXS
      token: "0x1a3acf6D19267E2d3e7f898f42803e90C9219062",
      feed: "0x6c0fe985d3cacbcde428b84fc9431792694d0f51",
    },
    {
      // MANA
      token: "0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4",
      feed: "0xa1cbf3fe43bc3501e3fc4b573e822c70e76a7512",
    },
    {
      // MKR
      token: "0x6f7C932e7684666C9fd1d44527765433e01fF61d",
      feed: "0xa070427bf5ba5709f70e98b94cb2f435a242c46c",
    },
    {
      // QUICK
      token: "0xB5C064F955D8e7F38fE0460C556a72987494eE17",
      feed: "0xa058689f4bca95208bba3f265674ae95ded75b6d",
    },
    {
      // APE
      token: "0xB7b31a6BC18e48888545CE79e83E06003bE70930",
      feed: "0x2ac3f3bfac8fc9094bc3f0f9041a51375235b992",
    },
    {
      // FTM
      token: "0xC9c1c1c20B3658F8787CC2FD702267791f224Ce1",
      feed: "0x58326c0f831b2dbf7234a4204f28bba79aa06d5f",
    },
    {
      // USDT
      token: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
      feed: "0x0a6513e40db6eb1b165753ad52e80663aea50545",
    },
    {
      // USDC
      token: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
      feed: "0xfe4a8cc5b5b2366c1b58bea3858e81843581b2f7",
    },
    {
      // DAI
      token: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
      feed: "0x4746dec9e833a82ec7c2c1356372ccf2cfcd2f3d",
    },
  ],
};

const stalePeriod = 60 * 60 * 25; // 25 hours
const sequencerUptimeFeed: any = {
  arbirum: "0xFdB631F5EE196F0ed6FAa767959853A9F217697D",
};

module.exports = async ({ network, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) => {
  const diamond = await hre.ethers.getContract("Diamond");
  const priceOracleFacet: PriceOracleFacet = await ethers.getContractAt("PriceOracleFacet", diamond.address);
  const networkFeeds = feeds[network.name];
  const _tokens = networkFeeds.map((feed: any) => feed.token);
  const _feeds = networkFeeds.map((feed: any) => feed.feed);

  const tx = await priceOracleFacet.setAssetFeeds(_tokens, _feeds);
  await tx.wait();

  if (sequencerUptimeFeed[network.name]) {
    const tx = await priceOracleFacet.setSequencerUptimeFeed(sequencerUptimeFeed[network.name]);
    await tx.wait();
  }

  await priceOracleFacet.setMaxStalePricePeriod(stalePeriod);

  console.log("Configuration complete");
};

module.exports.tags = ["configureFeeds"];
