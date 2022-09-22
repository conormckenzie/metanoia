// PASSING as of 2022-Aug-11

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

describe("ERC1155MultiUri_UserUpgradeable", function () {
	async function deployTestERC1155MultiUri_UserUpgradeableFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const TestERC1155MultiUri_UserUpgradeable = await ethers.getContractFactory("test_ERC1155MultiUri_UserUpgradeable");
		let hardhatTestERC1155MultiUri_UserUpgradeable = await TestERC1155MultiUri_UserUpgradeable.deploy();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

        const checkStateInvariants = async() => {
            
            // assumption: only IDs that are multiples of `nftInterval` are being used for testing.
            
            // 2: for all NFT IDs from 1 to `maxTest`, if NFT does exist, metadata isn't empty 
            // 3: for all NFT IDs from 1 to `maxTest`, if NFT is permanently unique, it is locked and there is only 1
            // 4: for all NFT IDs from 1 to `maxTest`, if NFT is locked and there is only 1, it is permanently unique
            
            // invariants from ERC1155MultiUri that do not hold in ERC1155MultiUri_UserUpgradeable:
            // 1: for all NFT IDs from 1 to `maxTest`, if NFT doesnt exist, metadata is empty

            let nftInterval = 10;
            let maxTest = 50;
            for (let id = nftInterval; id < maxTest; id += nftInterval) {
                // // 1
                // if (!(await hardhatTestERC1155MultiUri_UserUpgradeable.exists(id))) {
                //     await expect( await
                //         hardhatTestERC1155MultiUri_UserUpgradeable.uri(id)
                //     ).to.equal("");
                // }

                // 2
                if ((await hardhatTestERC1155MultiUri_UserUpgradeable.exists(id))) {
                    await expect( await
                        hardhatTestERC1155MultiUri_UserUpgradeable.uri(id)
                    ).to.not.equal("");
                }

                // 3
                if (
                    await hardhatTestERC1155MultiUri_UserUpgradeable.totalSupply(id) == 1
                    && await hardhatTestERC1155MultiUri_UserUpgradeable.cannotMintMore(id)
                ) {
                    expect(await hardhatTestERC1155MultiUri_UserUpgradeable.isPermanentlyUnique(id))
                    .to.equal(true);
                }

                // 4
                else if (await hardhatTestERC1155MultiUri_UserUpgradeable.isPermanentlyUnique(id)) {
                    expect(await hardhatTestERC1155MultiUri_UserUpgradeable.totalSupply(id))
                    .to.equal(1);
                    expect(await hardhatTestERC1155MultiUri_UserUpgradeable.cannotMintMore(id))
                    .to.equal(true);
                }
            }
        }

        // Fixtures can return anything you consider useful for your tests
        return { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 };
    }

    /// Tests from ERC1155MultiUri_UserUpgradeable
    it("----------------- ERC1155MultiUti_UserUpgradeable tests -----------------", async function () {
		expect(true).to.equal(true);
	});
    it("[B-1] Fails to update metadata of ID not owned by user", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr2.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.connect(addr1).safeUpdateURI(
            "uri",
            addr2.address,
            10
        )).to.be.revertedWith("ERC1155MultiURI_UserUpgradeable: caller is not owner nor approved");
        console.logWhereInline("here1");
        await checkStateInvariants();
    });
    it("[B-2] Fails to update metadata of that is not permanently unique", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.connect(addr1).safeUpdateURI(
            "uri",
            addr1.address,
            10
        )).to.be.revertedWith("Can only change URI on a token that is permanently unique");
        await checkStateInvariants();
    });
    it("[B-3] Allows updating of metadata of a permanently unique NFT, by its owner", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.connect(addr1).safeUpdateURI(
            "uri",
            addr1.address,
            10
        )).to.not.be.reverted;
        await checkStateInvariants();
    });
    it("[B-4] Fails to mint a permanently unique NFT", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.revertedWith("Token is non-mintable");
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithoutURI(
            addr1.address,
            10,
            1,
            0x0
        )).to.be.revertedWith("Token is non-mintable");
        await checkStateInvariants();
    });
    it("[B-5] Does not mark a multiply-minted or unminted locked NFT as permanently unique", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            20,
            2,
            0x0,
            "first uri"
        )).to.not.be.reverted;
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.lockMinting(
            20
        )).to.be.not.reverted;
        await expect(await hardhatTestERC1155MultiUri_UserUpgradeable.isPermanentlyUnique(
            20
        )).to.equal(false);
        await expect(await hardhatTestERC1155MultiUri_UserUpgradeable.isPermanentlyUnique(
            10
        )).to.equal(false);
        await checkStateInvariants();
    });
    it("[B-6] Does not mark a newly-minted NFT as permanently unique", async function () {
        const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.not.be.reverted;
        await expect(await hardhatTestERC1155MultiUri_UserUpgradeable.isPermanentlyUnique(
            10
        )).to.equal(false);
        await checkStateInvariants();
    });

	
	/// Tests from ERC1155MultiUri
    it("------------------------- ERC1155MultiUti tests -------------------------", async function () {
		expect(true).to.equal(true);
	});
	it("[A-1] Mints new NFT with non-empty metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it("[A-2] Fails to mint a new NFT with empty metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            ""
        )).to.be.revertedWith("Empty string is not a valid metadata URI");
        await checkStateInvariants();
	});
	it("[A-3] Fails to mint an existing NFT with metadata", async function() {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it("[A-4] Mints existing NFT without metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithoutURI(
            addr1.address,
            10,
            1,
            0x0,
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it(`[A-5] Fails to mint a new NFT without metadata`, async function() {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithoutURI(
            addr1.address,
            30,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it(`[A-6] Changes URI of an id to non-empty metadata`, async function() {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(await hardhatTestERC1155MultiUri_UserUpgradeable.setURI(
            30,
            "non-empty 0"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
    it(`[A-7] Changes the URI of ID 0`, async function() {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(await hardhatTestERC1155MultiUri_UserUpgradeable.setURI(
            0,
            "non-empty 1"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});

	it("[A-8] Fails to mint ID 0 with metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithURI(
            addr1.address,
            0,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});
    it("[A-9] Fails to mint ID 0 without metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155MultiUri_UserUpgradeable, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155MultiUri_UserUpgradeable.mintWithoutURI(
            addr1.address,
            0,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
    });
});