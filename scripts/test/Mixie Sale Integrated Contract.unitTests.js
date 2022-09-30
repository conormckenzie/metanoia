// PASSING as of 2022-

// NOTE: could still stand to be refactored into multiple (possibly parallelized) tests
// NOTE: still has console logs and other debugging artifacts, these could stand to be removed

const testEnabled = true;

if (!testEnabled) {
	return;
}

const {
	time,
	loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("@nomiclabs/hardhat-waffle");
//const { web3 } = require("web3");
var crypto = require('crypto');
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
var Accounts = require('web3-eth-accounts');
var accounts = new Accounts('ws://localhost:8546');

const consoleLogger = require("logger-line-number");
const colors = require('colors');
const { logger } = require("ethers");
colors.setTheme({
	custom1: ['grey', 'underline']
});

// USES:
// 	adding new method console.logWhere that is console.log but also prints line numbers of the resulting logs
//		in green
// 	adding new method console.logWhereInLine that is consoleLogger.log but prints in green
// 
// adapted from https://stackoverflow.com/questions/45395369/how-to-get-console-log-line-numbers-shown-in-nodejs
// need to figure out how to put this in its own file to reduce code duplication
// need to modify this so it does not add methods to the console method (which is not owned by me)
const addConsoleMethods = () => {
	console.logWhere = console.log;
	console.logWhereInline = consoleLogger.log;

	['logWhere', 'warn', 'error'].forEach((methodName) => {
		const originalMethod = console[methodName];
		console[methodName] = (...args) => {
			let initiator = 'unknown place';
			try {
				throw new Error();
			} catch (e) {
				if (typeof e.stack === 'string') {
					let isFirst = true;
					for (const line of e.stack.split('\n')) {
						const matches = line.match(/^\s+at\s+(.*)/);
						if (matches) {
							if (!isFirst) { // first line - current function
								// second line - caller (what we are looking for)
								initiator = matches[1];
								break;
							}
							isFirst = false;
						}
					}
				}
			}
			originalMethod.apply(console, [...args, '\n', `  at ${initiator}`.green]);
		};
	});
};
addConsoleMethods();

// if uncommented, this process stops console methods from producing output
// ['logWhere', 'logWhereInline', 'warn', 'error'].forEach((methodName) => {
// 	const originalMethod = console[methodName];
// 	console[methodName] = (...args) => {}
// })

var addresses = [];
const generateNewAddress = () => {
	var id = crypto.randomBytes(32).toString('hex');
	var privateKey = "0x" + id;
	//console.logWhere("SAVE BUT DO NOT SHARE THIS:", privateKey);

	var wallet = new ethers.Wallet(privateKey);
	//console.logWhere("Address: " + wallet.address);

	let address = wallet.address;
	// console.logWhere(`
	// 	wallet.address = ${wallet.address} , 
	// 	addresses[addresses.length - 1] = ${addresses[addresses.length - 1]}`
	// );
	return address;
};

function sleep(ms) {
	return new Promise((resolve) => {
	  setTimeout(resolve, ms);
	});
  }

describe("Mixie Sale Integrated Contract", function () {
	async function deployContractFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const Contract = await ethers.getContractFactory("MixieNftSaleIntegratedContractTest8");
		let hardhatContract = await Contract.deploy();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

        // Fixtures can return anything you consider useful for your tests
        return { Contract, hardhatContract, owner, addr1, addr2 };
    }
	it("[A-1] Gets to state 1", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		expect(true).to.equal(true);
	});
    it("[A-1.1] Successfully pauses if done by owner", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.emergencyPause())).to.not.be.reverted;
    });
    it("[A-1.2] Successfully unpauses if done by owner", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.emergencyPause())).to.not.be.reverted;
		await(expect(hardhatContract.unpause())).to.not.be.reverted;
    });
    it("[A-1.3] Fails to pause if not done by owner", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.connect(addr1).emergencyPause())).to.be.reverted;
    });
    it("[A-1.3] Fails to unpause if not done by owner", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.emergencyPause())).to.not.be.reverted;
		await(expect(hardhatContract.connect(addr1).unpause())).to.be.reverted;
    });
    it("[A-1.4] Fails to pause if already paused", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.emergencyPause())).to.not.be.reverted;
		await(expect(hardhatContract.emergencyPause())).to.be.reverted;
    });
    it("[A-1.5] Fails to unpause if already not paused", async function () {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		await(expect(hardhatContract.unpause())).to.be.reverted;
    });
	it("[A-2] Successfully mints new Mixie egg by owner", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
        await expect(hardhatContract.mintNextNftToAddress(addr1.address)).to.be.not.reverted;
	});
	it("[A-3] Fails to mint an NFT from non-approved address", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
        await expect(hardhatContract.connect(addr1).mintNextNftToAddress(addr1.address)).to.be.reverted;
	});
    it("[A-3.1] Fails to mint an NFT if paused", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
        await expect(hardhatContract.emergencyPause()).to.not.be.reverted;
        await expect(hardhatContract.mintNextNftToAddress(addr1.address)).to.be.reverted;
	});
	it("[A-4] Updates the royalty info and calculates royalties correctly", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let newRoyaltiesValue = 600;
		await expect(hardhatContract.setRoyaltyInfo(addr2.address, newRoyaltiesValue)).to.not.be.reverted;
		let examplePrice = 10**8;
		let expectedRoyalties = (examplePrice * newRoyaltiesValue) / 10000;
		let result = await hardhatContract.royaltyInfo(0, examplePrice);
		await expect(result[0]).to.equal(addr2.address);
		await expect(result[1]).to.equal(expectedRoyalties);
		// for (component in result) {
		// 	console.logWhereInline(`${component}`.bgYellow);
		// }
		// console.logWhereInline("---");
		// for (let i = 0; i < result.length; i++) {
		// 	console.logWhereInline(`${result[i]}`.bgYellow);
		// }
	});
	it("[A-5] Fails to update the royalty info if not done by owner", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let newRoyaltiesValue = 600;
		await expect(hardhatContract.connect(addr1).setRoyaltyInfo(addr2.address, newRoyaltiesValue)).to.be.reverted;
	});
    it("[A-5.1] Fails to update the royalty info if paused", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let newRoyaltiesValue = 600;
        await(expect(hardhatContract.emergencyPause())).to.not.be.reverted;
		await expect(hardhatContract.setRoyaltyInfo(addr2.address, newRoyaltiesValue)).to.be.reverted;
	});
	it("[A-6] Updates the contract URI correctly", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let expectedUri = "test URI";
		await expect(hardhatContract.setContractUri(expectedUri)).to.not.be.reverted;
		await expect(await hardhatContract.contractURI()).to.equal(expectedUri);
		let result = await hardhatContract.contractURI();
		// console.logWhereInline(result);
	});
	it("[A-7] Fails to update the contract URI if not done by owner", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let expectedUri = "test URI";
		await expect(hardhatContract.connect(addr1).setContractUri(expectedUri)).to.be.reverted;
	});
    it("[A-7.1] Fails to update the contract URI if paused", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let expectedUri = "test URI";
		await expect(hardhatContract.emergencyPause()).to.not.be.reverted;
		await expect(hardhatContract.setContractUri(expectedUri)).to.be.reverted;
	});

	// COUPONS
	it("[B-0.1] Adds an address successfully from admin", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.addressHasCoupon(addr1.address)).to.equal(false);
		expect(addressesLength).to.equal(6);
		await expect(hardhatContract.addAddress(
			addr1.address,
		)).to.not.be.reverted;
		await expect(await hardhatContract.couponListList())
		.to.equal(parseInt(addressesLength) + 1);
		await expect(await hardhatContract.idOf(addr1.address)).
		to.equal(parseInt(addressesLength) + 1);
	});
	it("[B-0.2] Adds multiple addresses successfully from admin", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		expect(addressesLength).to.equal(6);
		await expect(hardhatContract.addAddress(
			addr1.address,
		)).to.not.be.reverted;
		await expect(hardhatContract.addAddress(
			addr2.address,
		)).to.not.be.reverted;
		await expect(await hardhatContract.couponListList())
		.to.equal(parseInt(addressesLength) + 2);
		await expect(await hardhatContract.idOf(addr2.address)).
		to.equal(parseInt(addressesLength) + 2);
	});
	it("[B-1] Adds a coupon successfully (by admin)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(await hardhatContract.idOf(addr1.address)).
		to.equal(parseInt(addressesLength) + 1);
	});
	it("[B-2] Adds a coupon successfully from multiple people (by admin)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		await expect(await hardhatContract.addressHasCoupon(addr1.address)).to.equal(false);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(await hardhatContract.addressHasCoupon(addr1.address)).to.equal(true);
		await expect(await hardhatContract.couponListLength(addr2.address)).to.equal(0);
		for (let i = 1; i <= 5; i++) {
			await expect(hardhatContract.addCoupon(
				addr2.address,
				1,
				20,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr2.address)).to.equal(i);
		}
	});
	it("[B-3] Uses a coupon successfully from non-admin owner", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(hardhatContract.connect(addr1).useCoupon(
			addr1.address,
			1,
			21,
			1,
			10001
		)).to.not.be.reverted;
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(2);
	});
	it("[B-3.1] Fails to use a coupon from non-admin non-owner", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(hardhatContract.connect(addr2).useCoupon(
			addr1.address,
			1,
			21,
			1,
			10001
		)).to.be.reverted;
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(3);
	});
	it("[B-4] Removes an address successfully (by admin)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(hardhatContract.removeAddress(
			addr1.address
		)).to.not.be.reverted;
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		await expect(await hardhatContract.couponListList())
		.to.equal(parseInt(addressesLength));
	});
	it("[B-4.1] Fails to remove an address (by non-admin)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(hardhatContract.connect(addr1).removeAddress(
			addr1.address
		)).to.be.reverted;
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(3);
		await expect(await hardhatContract.couponListList())
		.to.equal(parseInt(addressesLength) + 1);
	});
	it("[B-5] Adds and uses a type 2 coupon successfully (by admin & owner respectively)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				2,
				0,
				10,
				20000 + i,
				1
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		await expect(hardhatContract.connect(addr1).useCoupon(
			addr1.address,
			2,
			0,
			10,
			20001
		)).to.not.be.reverted;
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(2);
	});
	it("[B-6] Adds and uses a multi-use coupon successfully (by admin & owner respectively)", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				2
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		for (let i = 1; i <= 2; i++) {
			await expect(hardhatContract.connect(addr1).useCoupon(
				addr1.address,
				1,
				21,
				1,
				10001
			)).to.not.be.reverted;
		}
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(2);
	});
	it("[B-6.1] Fails to use a non-existent coupon", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(hardhatContract.connect(addr1).useCoupon(
			addr1.address,
			1,
			21,
			1,
			10001
		)).to.be.reverted;
	});
	it("[B-6.2] Fails to use an already-used coupon", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
		for (let i = 1; i <= 3; i++) {
			await expect(hardhatContract.addCoupon(
				addr1.address,
				1,
				20 + i,
				1,
				10001,
				2
			)).to.not.be.reverted;
			await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
		}
		for (let i = 1; i <= 2; i++) {
			await expect(hardhatContract.connect(addr1).useCoupon(
				addr1.address,
				1,
				21,
				1,
				10001
			)).to.not.be.reverted;
		}
		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(2);
		await expect(hardhatContract.connect(addr1).useCoupon(
			addr1.address,
			1,
			21,
			1,
			10001
		)).to.be.reverted;
	});

	// USDC ESCROW - requires USDC contract forked from mainnet or on mainnet (how?)

	// it("[C-1] Receives USDC after approving", async function() {
	// 	const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
	// 	const usdcContract = await MyContract.attach(
	// 		"0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
	// 	);
	// 	await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(0);
	// 	for (let i = 1; i <= 3; i++) {
	// 		await expect(hardhatContract.addCoupon(
	// 			addr1.address,
	// 			1,
	// 			20 + i,
	// 			1,
	// 			10001,
	// 			2
	// 		)).to.not.be.reverted;
	// 		await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(i);
	// 	}
	// 	for (let i = 1; i <= 2; i++) {
	// 		await expect(hardhatContract.connect(addr1).useCoupon(
	// 			addr1.address,
	// 			1,
	// 			21,
	// 			1,
	// 			10001
	// 		)).to.not.be.reverted;
	// 	}
	// 	await expect(await hardhatContract.couponListLength(addr1.address)).to.equal(2);
	// 	await expect(hardhatContract.connect(addr1).useCoupon(
	// 		addr1.address,
	// 		1,
	// 		21,
	// 		1,
	// 		10001
	// 	)).to.be.reverted;
	// });

	// SALE

	it("[D-1] Returns the correct starting price", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		let units = await hardhatContract.getUnits();
		await expect(await hardhatContract.getUpdatedPrice()).to.equal(10000 * units)
	});
	it("[D-2*] Returns a price after a given time, between $10000 and $1000, and after 2 days it is at $1000", async function() {
		const { Contract, hardhatContract, owner, addr1, addr2 } = await loadFixture(deployContractFixture);
		let addressesLength = await hardhatContract.couponListList();
		let units = await hardhatContract.getUnits();
		let prices = [];
		let timestamps = [];
		for (let i = 0; i <= 50; i++) {
			let blockNumber = await ethers.provider.getBlockNumber();
			prices[i] = await hardhatContract.getUpdatedPrice();
			timestamps[i] = await (await ethers.provider.getBlock(blockNumber)).timestamp;
			console.logWhereInline(`i: ${i}, prices[i]: ${prices[i]}, timestamps[i]: ${timestamps[i]}, contractTimestamp: ${await hardhatContract.blockTimestamp()}`);
			if (i >= 1 && i <= 45) {
				await expect(await hardhatContract.getUpdatedPrice()).to.be.above(1000*units);
				await expect(await hardhatContract.getUpdatedPrice()).to.be.below(10000*units);
			}
			await network.provider.send("evm_increaseTime", [3600]); // 1hour
			await hardhatContract.updateState();
		}
		await expect(await hardhatContract.getUpdatedPrice()).to.equal(1000*units)
	});

});