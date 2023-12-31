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
    sepolia: {
      accounts: [process.env.PRIVATE_KEY || ""],
      url: process.env.SEPOLIA_RPC_URL || "",
      chainId: 11155111,
    },
    arbitrum: {
      accounts: [process.env.PRIVATE_KEY || ""],
      url: process.env.ARBITRUM_RPC_URL || "",
      chainId: 42161,
    },
    polygon: {
      accounts: [process.env.PRIVATE_KEY || ""],
      url: process.env.POLYGON_RPC_URL || "",
      chainId: 137,
    },
    optimism: {
      accounts: [process.env.PRIVATE_KEY || ""],
      url: process.env.OPTIMISM_RPC_URL || "",
      chainId: 10,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "ETHERSCAN_API_KEY",
      polygon: process.env.POLYGONSCAN_API_KEY || "POLYGONSCAN_API_KEY",
      arbitrumOne: process.env.ARBITRUMSCAN_API_KEY || "ARBITRUMSCAN_API_KEY",
      optimisticEthereum: process.env.OPTIMISMSCAN_API_KEY || "OPTIMISM_API_KEY",
    },
  },
};

export default config;
