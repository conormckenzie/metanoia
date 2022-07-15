const hre = require("hardhat");
require("dotenv").config({ path: ".env" });

const prompt = require('prompt-sync')();

async function main() {
    const contractName = prompt('Name of contract to deploy: ');
    const Contract = await hre.ethers.getContractFactory(contractName);
    const c = await Contract.deploy();
    await c.deployed();
    console.log("Deployed contract to:", c.address);
    console.log("Contract is not verified.", c.address);
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});