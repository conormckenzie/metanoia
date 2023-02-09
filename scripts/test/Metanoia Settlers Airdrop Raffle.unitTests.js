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

describe("Founding Settlers Airdrop Raffle", function () {
	async function SettlersAirDropRaffleFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const SettlersAirDropRaffle = await ethers.getContractFactory("$SettlersAirDropRaffle");
		const hardhatdeploy = await SettlersAirDropRaffle.deploy();
		const SettlerAirdropRaffle2 = await ethers.getContractFactory("SettlersAirDropRaffle");
		const hardhatdeploy2 = await SettlerAirdropRaffle2.deploy();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

        // Fixtures can return anything you consider useful for your tests
        return { SettlersAirDropRaffle,
        	 hardhatdeploy,
		 SettlerAirdropRaffle2,
        	 hardhatdeploy2,
        	 owner, 
        	 addr1, 
        	 addr2 };
    }
	it("[A-1] Run getDistinctPseudoRandomNumbers without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
			
		const tryTo_GDPRN = await expect(await hardhatdeploy.$_getDistinctPseudoRandomNumbers(2000000, 1, 100)).to.not.be.reverted;
			
	});
	
	it("[A-2] Run _rand without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
			
		const tryTo_rand = await expect(await hardhatdeploy.$_rand(2000000, 1)).to.not.be.reverted;
			
	});
	
	it("[A-3] Run _resetRandomNumbers without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTo_resetRandomNumbers = await expect(await hardhatdeploy.$_resetRandomNumbers(1)).to.not.be.reverted;
			
	});
	
	it("[A-4] run senditems and be reverted with reason insufficient balance", async function () {
		const { SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTo_sendItems = await expect(hardhatdeploy2.sendItems(addr1.address,1,1)).to.be.revertedWith("ERC1155: insufficient balance for transfer");
			
	});
	
	it("[A-5] run senditem and be reverted with insufficient balance", async function () {
		const { SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTo_sendItem = await expect(hardhatdeploy2.sendItem(addr1.address,1)).to.be.revertedWith("ERC1155: insufficient balance for transfer");
			
	});
	
	it("[A-6] try to run _mintByAirdrop without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTo_mintByAirdrop = await expect(await hardhatdeploy.$_mintByAirdrop(100,1,"")).to.not.be.reverted;
			
	});
		
	it("[A-7] try to run mintExistingByAirdrop without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintWithUri = await hardhatdeploy.$_mintWithURI(addr1.address,1,1,"0x0012","a");
		
		const tryTomintExistingByAirdrop = await expect(await hardhatdeploy2.mintExistingByAirdrop(100,1)).to.not.be.reverted;
			
	});
	
	it("[A-8] try to run mintnewbyAirdrop without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintNewByAirdrop = await expect(await hardhatdeploy2.mintNewByAirdrop(1100,1, "aa")).to.not.be.reverted;
			
	});

	it("[A-9] try to _mintByraffle without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintWithUri = await hardhatdeploy.$_mintWithURI(addr1.address,110,1,"0x0012","a");
		
		const tryTo_mintByRaffle = await expect(await hardhatdeploy.$_mintByRaffle(110,1,1,1,"a")).to.not.be.reverted;
			
	});
	
	it("[A-10] try to mintByraffle without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);	
		
		const tryTomintByRaffle = await expect(await hardhatdeploy2.mintByRaffle(150,1,1,1000000)).to.not.be.reverted;
			
	});
	
	it("[A-11] try to mintNewByRaffle without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintWithUri = await hardhatdeploy.$_mintWithURI(addr1.address,1500,1,"0x0012","a");	

		const tryTomintNewByRaffle = await expect(await hardhatdeploy2.mintNewByRaffle(1500,1,1,1,"a")).to.not.be.reverted;
			
	});
	
	it("[A-12] try to  mint to extra holders without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintNewToExtrasHolder = await hardhatdeploy2.mintNewToExtrasHolder(1,1,"a")
		
		const tryTomintToExtrasHolder = await expect(hardhatdeploy2.mintToExtrasHolder(1,1)).to.not.be.reverted;
			
	});
	
	it("[A-13] try to mint new to extra holders without being reverted", async function () {
		const { SettlersAirDropRaffle, hardhatdeploy, SettlersAirDropRaffle2, hardhatdeploy2, owner, addr1, addr2 } = await loadFixture(SettlersAirDropRaffleFixture);
		
		const tryTomintNewToExtrasHolder = await expect(hardhatdeploy2.mintNewToExtrasHolder(1,1,"a")).to.not.be.reverted;
			
	});
	
});
