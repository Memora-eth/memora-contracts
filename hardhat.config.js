require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()
require("@nomicfoundation/hardhat-verify");


// const RSK_MAINNET_RPC_URL = process.env.RSK_MAINNET_RPC_URL;
const RSK_MAINNET_RPC_URL = "";
const RSK_TESTNET_RPC_URL = process.env.RSK_TESTNET_RPC_URL;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    rskMainnet: {
      url: RSK_MAINNET_RPC_URL,
      chainId: 30,
      gasPrice: 60000000,
      accounts: [process.env.PRIVATE_KEY]
    },
    rskTestnet: {
      url: 'https://public-node.testnet.rsk.co/',
      chainId: 31,
      gasPrice: 120000000,
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  namedAccounts: {
    deployer: {
      default: 0, // Default is the first account
      mainnet: 0,
    },
    owner: {
      default: 0,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  sourcify: {
    enabled: false
  },
  etherscan: {
    apiKey: {
      // Is not required by blockscout. Can be any non-empty string
      rskTestnet: 'RSK_TESTNET_RPC_URL',
      rskMainnet: 'RSK_MAINNET_RPC_URL'
    },
    customChains: [
      {
        network: "rskTestnet",
        chainId: 31,
        urls: {
          apiURL: "https://rootstock-testnet.blockscout.com/api/",
          browserURL: "https://rootstock-testnet.blockscout.com/",
        }
      },
      {
        network: "rskMainnet",
        chainId: 30,
        urls: {
          apiURL: "https://rootstock.blockscout.com/api/",
          browserURL: "https://rootstock.blockscout.com/",
        }
      },

    ]
  },
};
