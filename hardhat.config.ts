import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config } from "dotenv";

config();

const _config: HardhatUserConfig = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [`${process.env.PRIVATE_KEY1}`],
    },
  },

  gasReporter: {
    currency: "CHF",
    gasPrice: 21,
    enabled: true,
  },
};

export default _config;
