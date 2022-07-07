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
    const contract = await hre.ethers.getContractFactory(contractName);
    const time = 40
    const c = await contract.deploy();
    await c.deployed();
    console.log("Deployed contract to:", c.address);
    console.log(`waiting for ${time} seconds`);
    await sleep(1000*time);
    await hre.run("verify:verify", {
        address: c.address,
        constructorArguments: [],
    });
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});