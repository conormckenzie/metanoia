const hre = require("hardhat");

async function main() {
    const latestBlock = await hre.ethers.provider.getBlock("latest");
    console.log("latest block:", latestBlock.number);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
    });
