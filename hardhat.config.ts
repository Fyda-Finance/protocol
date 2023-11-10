import "module-alias/register";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import "solidity-docgen";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    goerli: {
      accounts: [
        process.env.PRIVATE_KEY || "",
        process.env.MY_PRIVATE_KEY || "",
      ],
      url: process.env.RPC_URL || "",
      chainId: 5,
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY || "ETHERSCAN_API_KEY",
    },
    customChains: [
      {
        network: "goerli",
        chainId: 5,
        urls: {
          apiURL: "https://api-goerli.etherscan.io/",
          browserURL: "https://goerli.etherscan.io/",
        },
      },
    ],
  },
};

export default config;
