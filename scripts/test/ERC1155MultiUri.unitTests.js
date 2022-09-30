// PASSING as of 2022-Sep-20

// NOTE: could still stand to be refactored into multiple (possibly parallelized) tests
// NOTE: still has console logs and other debugging artifacts, these could stand to be removed

const testEnabled = false;

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

describe("ERC1155MultiUri", function () {
	async function deployTestERC1155MultiUriFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const TestERC1155MultiUri = await ethers.getContractFactory("TestERC1155MultiUri");
		let hardhatTestERC1155MultiUri = await TestERC1155MultiUri.deploy();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

        const checkStateInvariants = async() => {
            // for all NFT IDs from 1 to `maxTest`, if NFT doesnt exist, metadata is empty 
            // for all NFT IDs from 1 to `maxTest`, if NFT does exist, metadata isn't empty 

            let maxTest = 100;
            // console.logWhereInline("entry:checkStateInvariants");
            for (let id = 1; id < maxTest; id++) {
                if (!(await hardhatTestERC1155MultiUri.exists(id))) {
                    // console.logWhereInline(`here 1: id ${id}`)
                    await expect( await
                        hardhatTestERC1155MultiUri.uri(id)
                    ).to.equal("");
                }
                else {
                    // console.logWhereInline(`here 2: id ${id}`)
                    await expect( await
                        hardhatTestERC1155MultiUri.uri(id)
                    ).to.not.equal("");
                }
            }
        }

        // Fixtures can return anything you consider useful for your tests
        return { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 };
    }
	
	
	
	it("Mints new NFT with non-empty metadata", async function () {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
        await expect(await hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it("Fails to mint a new NFT with empty metadata", async function () {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await expect(hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            20,
            1,
            0x0,
            ""
        )).to.be.revertedWith("Empty string is not a valid metadata URI");
        await checkStateInvariants();
	});
	it("Fails to mint an existing NFT with metadata", async function() {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            20,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            20,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it("Mints existing NFT without metadata", async function () {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            10,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155MultiUri.mintWithoutURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            10,
            1,
            0x0,
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it(`Fails to mint a new NFT without metadata`, async function() {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await expect(hardhatTestERC1155MultiUri.mintWithoutURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            30,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it(`Changes URI of an id to non-empty metadata`, async function() {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await expect(await hardhatTestERC1155MultiUri.setURI(
            30,
            "non-empty 0"
        )).to.be.not.reverted;
	});
    it(`Changes the URI of ID 0`, async function() {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await expect(await hardhatTestERC1155MultiUri.setURI(
            0,
            "non-empty 1"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});

	it("Fails to mint ID 0 with metadata", async function () {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
		await expect(hardhatTestERC1155MultiUri.mintWithURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            0,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});
    it("Fails to mint ID 0 without metadata", async function () {
		const { TestERC1155MultiUri, hardhatTestERC1155MultiUri, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUriFixture);
        await expect(hardhatTestERC1155MultiUri.mintWithoutURI(
            "0xc0ffee254729296a45a3885639AC7E10F9d54979",
            0,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
    });
});