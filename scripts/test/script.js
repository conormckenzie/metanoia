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

    const Address = prompt('Enter Address:');
    const TicketID = prompt('Enter ID:');
    const Contract = await hre.ethers.getContractFactory('SettlersTickets');
    const time = 2.2;
    const c = await Contract.deploy();
    await c.deployed();
    console.log("Deployed contract to:", c.address);
    console.log("waiting for ${time} seconds");
    await sleep(1000*time);
    await hre.run("verify:verify", {
        address: c.address,
        constructorArguments: [],
    });
    Contract.addAddress(Address, true);
    Contract.sendTicket(Address, TicketID);

}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});