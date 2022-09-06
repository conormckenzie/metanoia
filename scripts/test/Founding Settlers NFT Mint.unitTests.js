// PASSING as of 2022-Aug-11

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

// Need to run these tests with the FOunding Settlers List being empty, partly full, full, and overfull 

describe("Founding Settlers NFT Mint", function () {
	async function deployFoundingSettlersNftMintFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const FoundingSettlersNftMint = await ethers.getContractFactory("SettlersTickets");
		let hardhatFoundingSettlersNftMint = await FoundingSettlersNftMint.deploy();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

    // Fixtures can return anything you consider useful for your tests
    return { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 };
  }
	const addAddress = async (hardhatFoundingSettlersNftMint, address) => {
		await hardhatFoundingSettlersNftMint.addAddress(address, true);
	};
	const tryToAddAddress = async (hardhatFoundingSettlersNftMint, address) => {
		await hardhatFoundingSettlersNftMint.addAddress(address, false);
	};
	
	const removeAddress = async (hardhatFoundingSettlersNftMint, address) => {
		await hardhatFoundingSettlersNftMint.removeAddress(address, true);
	}; 
	const tryToRemoveAddress = async (hardhatFoundingSettlersNftMint, address) => {
		await hardhatFoundingSettlersNftMint.removeAddress(address, false);
	};
	
	const sendTicket = async (hardhatFoundingSettlersNftMint, address, id) => {
		await hardhatFoundingSettlersNftMint.sendTicket(address, id);
	};
	
	let maxSupply = 100;
	const checkGlobalInvariants = async () => {
		// exactly `mxSupply` (100) NFTs have been minted: checks IDs 1 to 100
		let totalMinted = 0;
		for (let id = 1; id < maxSupply; id++) {
			totalMinted += await hardhatFoundingSettlersNftMint.totalSupply(id);
		}
		expect(totalMinted).to.equal(maxSupply);
	}
	
	const checkMintInvariants = async() => {
		// no more than maxSupply (100) NFTs are minted
		let totalMinted = 0;
		for (let id = 1; id < maxSupply; id++) {
			totalMinted += await hardhatFoundingSettlersNftMint.totalSupply(id);
		}
		expect(totalMinted <= maxSupply).to.equal(true);
	}
	
	const checkState1Invariants = async () => {
		// each founding settler gets 1 NFT
		let eachFoundingSettlerGetsOneNft = true;
		let _totalSupply = 0;
		const testLength = await hardhatFoundingSettlersNftMint.addresses_length();
		for (let i = 1; i <= testLength; i++) {
			let _address = await hardhatFoundingSettlersNftMint.addresses_list(i);
			let _balance = 0;
			for (let id = 1; id <= testLength; id++) {
				let __balance = await hardhatFoundingSettlersNftMint.balanceOf(_address, id);
				_balance += __balance;
			}
			_totalSupply += _balance;
			if (_balance != 1) {
				eachFoundingSettlerGetsOneNft = false;
				console.error(`Each Founding Settler gets 1 NFT: ` + `${eachFoundingSettlerGetsOneNft}`.red + `\nlist member[${i}] has balance ${_balance}`);
				break;
			}
		}
		expect(eachFoundingSettlerGetsOneNft).to.equal(true);
	
		// all remainders go to extrasHolder
		let allRemaindersGoToExtrasHolder = true;
		let extrasHolder = await hardhatFoundingSettlersNftMint.extrasHolder();
		let extrasHolderTickets = []; 
		let firstNonzeroIndex = 999;
		for (let id = 1; id <= maxSupply; id++) {
			extrasHolderTickets[i] = await hardhatFoundingSettlersNftMint.balanceOf(extrasHolder, id);
		}
		let extrasHolderTicketsSum = 0;
		for (let i = 1; i <= maxSupply; i++) {
			extrasHolderTicketsSum += extrasHolderTickets[i];
			if (extrasHolderTickets[i] > 0 && i < firstNonzeroIndex) {
				firstNonzeroIndex = i;
			}
		}
		if (extrasHolderTicketsSum == 0) {
			console.logWhereInline("extrasHolder holds no tickets");
		}
		expect(_totalSupply + extrasHolderTicketsSum).to.equal(maxSupply);
	}
	it("Gets to state 1", async function () {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		expect(true).to.equal(true);
	});
	it("Successfully adds an address", async function () {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		for (let i = 1; i < addresses.length; i++) {
			let testAddressIndex = await hardhatFoundingSettlersNftMint.addresses_listInv(addresses[i])
			if (testAddressIndex == 0) { // if test address is not already in list
				await expect(addAddress(hardhatFoundingSettlersNftMint, addresses[i], true)).to.be.not.reverted;
			}
			if (i == addresses.length) {
				console.error("Out of addresses to add to list");
				expect(false).to.equal(true);
			}
		}
	});
	it("Successfully removes an address", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let testLength = await hardhatFoundingSettlersNftMint.addresses_length;
		if (testLength == 0) {
			console.logWhereInline("No addresses in list to remove");
		}
		// console.logWhereInline("BEEP "+await hardhatFoundingSettlersNftMint.addresses());
		// console.logWhereInline("BEEP "+await hardhatFoundingSettlersNftMint.addresses_length);
		let testAddress = await hardhatFoundingSettlersNftMint.addresses_list(1);
		await expect(removeAddress(hardhatFoundingSettlersNftMint, testAddress, true)).to.be.not.reverted;
	});
	it(`Returns total supply of ${maxSupply}`, async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let totalSupply = await hardhatFoundingSettlersNftMint["totalSupply()"]();
		await expect(totalSupply).to.equal(maxSupply);
	});
	it("Successfully sends ticket", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let extrasHolder = await hardhatFoundingSettlersNftMint.extrasHolder();
		let extrasHolderTickets = []; 
		let firstNonzeroIndex = 999;
		// console.logWhereInline(`Beep`.bgGreen);
		for (let id = 1; id <= maxSupply; id++) {
			extrasHolderTickets[id] = await hardhatFoundingSettlersNftMint.balanceOf(extrasHolder, id);
		}
		let extrasHolderTicketsSum = 0;
		for (let i = 1; i <= maxSupply; i++) {
			extrasHolderTicketsSum += extrasHolderTickets[i];
			if (extrasHolderTickets[i] > 0 && i < firstNonzeroIndex) {
				firstNonzeroIndex = i;
			}
		}
		// console.logWhereInline(`Beep3`.bgGreen);
		if (extrasHolderTicketsSum == 0) {
			console.logWhereInline("extrasHolder holds no tickets");
			expect(false).to.equal(true);
		}
		else {
			// console.logWhereInline(`BOOP`);
			await expect(sendTicket(hardhatFoundingSettlersNftMint, addr2.address, firstNonzeroIndex)).to.be.not.reverted;
		}
		// console.logWhereInline(`Beep2`.bgGreen);
	});
	it("Fails to send a ticket from non-owner address", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let extrasHolder = await hardhatFoundingSettlersNftMint.extrasHolder();
		let extrasHolderTickets = []; 
		let firstNonzeroIndex = 999;
		for (let id = 1; id <= maxSupply; id++) {
			extrasHolderTickets[id] = await hardhatFoundingSettlersNftMint.balanceOf(extrasHolder, id);
		}
		let extrasHolderTicketsSum = 0;
		for (let i = 1; i <= maxSupply; i++) {
			extrasHolderTicketsSum += extrasHolderTickets[i];
			if (extrasHolderTickets[i] > 0 && i < firstNonzeroIndex) {
				firstNonzeroIndex = i;
			}
		}
		if (extrasHolderTicketsSum == 0) {
			console.logWhereInline("extrasHolder holds no tickets");
			expect(false).to.equal(true);
		}
		await expect(hardhatFoundingSettlersNftMint.connect(addr1).sendTicket(addr2.address, firstNonzeroIndex)).to.be.reverted;
	});
	it("Updates the royalty info and calculates royalties correctly", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let newRoyaltiesValue = 600;
		await expect(hardhatFoundingSettlersNftMint.setRoyaltyInfo(addr2.address, newRoyaltiesValue)).to.not.be.reverted;
		let examplePrice = 10**8;
		let expectedRoyalties = (examplePrice * newRoyaltiesValue) / 10000;
		let result = await hardhatFoundingSettlersNftMint.royaltyInfo(0, examplePrice);
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
	it("Fails to update the royalty info if not done by owner", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let newRoyaltiesValue = 600;
		await expect(hardhatFoundingSettlersNftMint.connect(addr1).setRoyaltyInfo(addr2.address, newRoyaltiesValue)).to.be.reverted;
	});
	it("Updates the contract URI correctly", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let expectedUri = "test URI";
		await expect(hardhatFoundingSettlersNftMint.setContractUri(expectedUri)).to.not.be.reverted;
		await expect(await hardhatFoundingSettlersNftMint.contractURI()).to.equal(expectedUri);
		let result = await hardhatFoundingSettlersNftMint.contractURI();
		// console.logWhereInline(result);
	});
	it("Fails to update the contract URI if not done by owner", async function() {
		const { FoundingSettlersNftMint, hardhatFoundingSettlersNftMint, owner, addr1, addr2 } = await loadFixture(deployFoundingSettlersNftMintFixture);
		let expectedUri = "test URI";
		await expect(hardhatFoundingSettlersNftMint.connect(addr1).setContractUri(expectedUri)).to.be.reverted;
	});
});