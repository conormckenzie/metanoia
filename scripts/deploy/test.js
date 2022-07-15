const hre = require("hardhat");
const fs = require('fs');
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

const prompt = require('prompt-sync')();

function sleep(ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
}

//  '../../.openzeppelin/unknown-80001.json'
fs.readFile('deploy.js', 'utf8', function(err, data) {
    console.log("here2");
    if (err) {
        console.log(`Error reading file from disk: ${err}`);
    } else {
        console.log("here");

        // parse JSON string to JSON object
        const databases = JSON.parse(data);

        // print all databases
        databases.forEach(db => {
            console.log(`${db.name}: ${db.type}`);
        });
    }
});


async function main() {
    
    
    // const contractName = prompt('Name of contract to deploy: ');
    // const Contract = await hre.ethers.getContractFactory(contractName);
    // const time = 40
    // const c = await upgrades.deployProxy(Contract, [], { initializer: 'initialize' });
    // // const c = await contract.deploy();
    // await c.deployed();
    // console.log("Deployed contract ", contractName , " proxy to: ", c.address);
    // console.log(`waiting for ${time} seconds`);
    // await sleep(1000*time);
    // await hre.run("verify:verify", {
    //     address: c.address,
    //     constructorArguments: [],
    // });
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});