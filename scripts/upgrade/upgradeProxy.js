// NOTE: This script does not verify the new implementation contract - select "Verify" 
// afterwards using the implementation contract address. 

const { contract } = require("@openzeppelin/test-environment");
const { ethers, upgrades } = require("hardhat");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

const prompt = require('prompt-sync')();

async function main() {
    const contractName = prompt('Name of new implementation contract: ');
    const Contract = await hre.ethers.getContractFactory(contractName);

    const contractAddress = prompt('Address of proxy contract: ');
    const contract = await upgrades.upgradeProxy(contractAddress, Contract);
    console.log("Proxy upgraded - check ", contractAddress, " on etherscan to find new implementation address");
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});