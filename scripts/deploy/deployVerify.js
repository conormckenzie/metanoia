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
    let c_temp;
    let _err;
    do {
        _err = false;
        try {
            c_temp = await Contract.deploy();
            await c_temp.deployed();
        } catch (err) {
            console.error(err);
            _err = err;
        }
    } while (_err)
    const c = c_temp
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