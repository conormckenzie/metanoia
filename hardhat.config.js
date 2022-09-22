require('dotenv').config(); //from mulitple tutorials

require("@nomiclabs/hardhat-ethers"); //from Polygon tutorial
require("@nomiclabs/hardhat-etherscan"); //from Polygon tutorial

require("@nomicfoundation/hardhat-toolbox"); // from hardhat.org setup tutorial

// require('hardhat-ethernal'); //potential blockchain explorer

require("@nomiclabs/hardhat-waffle"); //from other tutorial

require('hardhat-deploy'); //from OpenZeppelin tutorial

require('@openzeppelin/hardhat-upgrades'); //from OpenZeppelin upgrades tutorial

require("@nomiclabs/hardhat-waffle"); //from polygonscan verify tutorial

require('solidity-coverage'); //from solidity-coverage github 
  // referenced by https://ethereum.org/en/developers/docs/smart-contracts/testing/

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.4"
      },
      {
        version: "0.8.2"
      },
    ],
  },
  defaultNetwork: 'hardhat',
  networks: {
    // localhost: {
    //   url: "http://127.0.0.1:8545"
    // },
    hardhat: {
      accounts:{mnemonic: process.env.MNEMONIC},
      chainId: 1337
    },
    matic_testnet: {
      url: "https://matic-mumbai.chainstacklabs.com/",
      accounts: [process.env.PRIVATE_KEY]
    },
    matic: {
      url: "https://polygon-rpc.com",
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  // ethernal: {
  //   disableSync: false, // If set to true, plugin will not sync blocks & txs
  //   disableTrace: false, // If set to true, plugin won't trace transaction
  //   workspace: process.env.CURRENT_HARDHAT_NETWORK, // Set the workspace to use, will default to the default workspace (latest one used in the dashboard). It is also possible to set it through the ETHERNAL_WORKSPACE env variable
  //   uploadAst: true, // If set to true, plugin will upload AST, and you'll be able to use the storage feature (longer sync time though)
  //   disabled: false, // If set to true, the plugin will be disabled, nohting will be synced, ethernal.push won't do anything either
  //   resetOnStart: false, // Pass a workspace name to reset it automatically when restarting the node, note that if the workspace doesn't exist it won't error
  //   email: process.env.ETHERNAL_EMAIL,
  //   password: process.env.ETHERNAL_PASSWORD,
  // },
  namedAccounts: {
    account0: 0,
  },
  paths: {
    sources: "./contracts",
    tests: "./scripts/test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  etherscan: {
    apiKey: {
      polygon: process.env.POLYGONSCAN_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
    },
  },
};
