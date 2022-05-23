require('dotenv').config(); //from mulitple tutorials

require("@nomiclabs/hardhat-ethers"); //from Polygon tutorial
require("@nomiclabs/hardhat-etherscan"); //from Polygon tutorial

require("@nomiclabs/hardhat-waffle"); //from other tutorial

require('hardhat-deploy'); //from OpenZeppelin tutorial

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 
 	
module.exports = {
  solidity: "0.8.1",
  defaultNetwork: 'hardhat',
  networks: {
    // localhost: {
    //   url: "http://127.0.0.1:8545"
    // },
    hardhat: {
      accounts:{mnemonic: "test test test test test test test test test test test junk"},
      chainId: 1337
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  namedAccounts: {
    account0: 0,
  }
};
