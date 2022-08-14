// PASSING as of 2022-Aug-11

// NOTE: could still stand to be refactored into multiple (possibly parallelized) tests
// NOTE: still has console logs and other debugging artifacts, these could stand to be removed

const {
	time,
	loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
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

	['logWhere', 'logWhereInline', 'warn', 'error'].forEach((methodName) => {
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

var addresses = [];
const generateNewAddress = async () => {
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

//

var descriptions = {
	ops: [`Initialize the address list correctly`, `Add an address`, `Remove an address`],
	states: [`Empty list`, `Non-empty list`],
	elementTypes: [`Exists in the list`, `Doesn't exist in the list`, `The zero address`, `bad input`]
}

for (let i = 0; i < descriptions.ops.length * descriptions.states.length * descriptions.elementTypes.length; i++) {

}

describe("Founding Settlers NFT Mint", async function () {
	it("true", async function () {
		consoleLogger.log(`test`.yellow);
		console.logWhereInline(`test2`.yellow);
	});
});