// NOTE: This script does not verify the contract - select "Verify" 
// afterwards using the implementation contract address. 

const hre = require("hardhat");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

const prompt = require('prompt-sync')();

function sleep(ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
}

async function main() {
    const contractName = prompt('Name of contract to deploy: ');
    const Contract = await hre.ethers.getContractFactory(contractName);
    const time = 40
    const c = await upgrades.deployProxy(Contract, [], { initializer: 'initialize' });
    // const c = await contract.deploy();
    await c.deployed();
    console.log("Deployed contract prxoy for ", contractName , " to:", c.address);
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});