require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    hardhat: {},
    // localhost: {
    //   url: "http://127.0.0.1:8545"
    // },
    // goerli: {
    //   url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [PRIVATE_KEY]
    // },
    // sepolia: {
    //   url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [PRIVATE_KEY]
    // },
    // mainnet: {
    //   url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [PRIVATE_KEY]
    // },
    // Add your custom network here
    rootstock: {
      url: "https://rpc.testnet.rootstock.io/4MmYWv9uFySkJ1CSYQdKRIFfOa7oPa-T",
      chainId: 31,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
  },
};
