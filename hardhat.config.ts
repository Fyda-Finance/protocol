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
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "ETHERSCAN_API_KEY",
      polygon: process.env.POLYGONSCAN_API_KEY || "POLYGONSCAN_API_KEY",
    },
    customChains: [
      {
        network: "sepolia",
        chainId: 5,
        urls: {
          apiURL: "https://api-sepolia.etherscan.io/",
          browserURL: "https://sepolia.etherscan.io/",
        },
      },
      {
        network: "polygon",
        chainId: 137,
        urls: {
          apiURL: "https://api.polygonscan.com/",
          browserURL: "https://polygonscan.com/",
        },
      },
    ],
  },
};

export default config;
