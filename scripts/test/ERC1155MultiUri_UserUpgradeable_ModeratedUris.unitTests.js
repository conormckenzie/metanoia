// Currently FAILING as of 2022-Sep-22

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

describe("ERC1155MultiUri_UserUpgradeable_ModeratedUris", function () {

	async function deployTestERC1155MultiUri_UserUpgradeableFixture() {
    
		const [owner, addr1, addr2] = await ethers.getSigners();
		const TestERC1155C = await ethers.getContractFactory("test_ERC1155MultiUri_UserUpgradeable_ModeratedUris");
		let hardhatTestERC1155C = await TestERC1155C.deploy();
        await hardhatTestERC1155C.initialize();
		let addresses = [];
		addresses[0] = "0x0000000000000000000000000000000000000000";
		for (let i = 1; i <= 50; i++) {
			addresses[i] = generateNewAddress();
			// console.logWhereInline(addresses[i]);
		}

        const populateEntries = async (maxEntries) => {
            function NewEntry(id, uri, approved) { 
                this.id = id;
                this.uri = uri; 
                this.approved = approved; 
            };
            entries = [];

            // console.logWhereInline("populateEntries 1".green);

            let randId;
            let randUri;
            let randApproved;
            // fill the first half of entries with sparse data
            for (let i = 1; i < maxEntries/2; i++) {
                randId = Math.ceil(Math.random()*10000);
                randUri;
                if (Math.ceil(Math.random()*2) % 2 == 0) {
                    randUri = "baseline_sampleuri";
                }
                else {
                    randUri = Math.ceil(Math.random()*10**6).toString().concat("_sampleuri");
                }
                randApproved = (Math.ceil(Math.random()*2) % 2 == 0) ? true: false;
                entries[i] = NewEntry(randId, randUri, randApproved);
                if (randApproved && randId % 2 == 0) {
                    await hardhatTestERC1155C.approveMetadataForAll(randUri);
                }
                else if (randApproved) {
                    await hardhatTestERC1155C.approveMetadataForId(randId, randUri);
                }
                else if (randId % 2 == 0) {
                    await hardhatTestERC1155C.unapproveMetadataForAll(randUri);
                }
                else {
                    await hardhatTestERC1155C.unapproveMetadataForId(randId, randUri);
                }
            }
            // fill the second half of entries with (dense) likely-repeating data
            for (let i = maxEntries/2; i < maxEntries; i++) {
                randId = Math.ceil(Math.random()*4);
                randUri;
                if (Math.ceil(Math.random()*2) % 2 == 0) {
                    randUri = "baseline_sampleuri";
                }
                else {
                    randUri = Math.ceil(Math.random()*3).toString().concat("_sampleuri");
                }
                randApproved = (Math.ceil(Math.random()*2) % 2 == 0) ? true: false;
                entries[i] = NewEntry(randId, randUri, randApproved);
                if (randApproved && randId % 2 == 0) {
                    await hardhatTestERC1155C.approveMetadataForAll(randUri);
                }
                else if (randApproved) {
                    await hardhatTestERC1155C.approveMetadataForId(randId, randUri);
                }
                else if (randId % 2 == 0) {
                    await hardhatTestERC1155C.unapproveMetadataForAll(randUri);
                }
                else {
                    await hardhatTestERC1155C.unapproveMetadataForId(randId, randUri);
                }
                // console.logWhereInline(`populateEntries 1A; i=${i}, uri=${entries[i].uri}`.green);
            } 
            // console.logWhereInline("populateEntries 3".green);
        }

        const getEntry = async (_entryId) => {
            let tempStorage = await hardhatTestERC1155C.debug_get_entry(_entryId);
            let entry = {};
            entry._entryId = tempStorage[0];
            entry.id = tempStorage[1];
            entry.uri = tempStorage[2];
            entry.approved = tempStorage[3];
            return entry;
        }

        const checkModeratedUriStateInvariants = async () => {

            // 1: each entry should be in sequential order, with _entryId matching its order
            // 2: indexWithIdUri, indexesWithUri, indexesWithId, and Entries must be consistent
            // 3: each entry other than 0 should have non-empty uri

            let maxId = 0;
            let maxEntryLength = await hardhatTestERC1155C.debug_get_entries_length();
            // console.logWhereInline(`checkState 0: length: ${maxEntryLength}`.yellow);
            let maxIndexLength = maxEntryLength;

            function Entry() { 
                this._entryId = null; 
                this.id = null;
                this.uri = null; 
                this.approved = null; 
            };
            let entries = [];
            let indexesWithId = [];
            let bytes32hash;
            let indexesWithUri = {};
            let indexWithIdUri;

            // console.logWhereInline("checkState 1".green);

            // get entries
            for (let _entryId = 0; _entryId < maxEntryLength; _entryId += 1) {
                // console.logWhereInline("checkState 1A".green);
                entries[_entryId] = new Entry();
                let tempStorage = await hardhatTestERC1155C.debug_get_entry(_entryId);
                // console.logWhereInline("checkState 1B".green);
                entries[_entryId]._entryId = tempStorage[0];
                entries[_entryId].id = tempStorage[1];
                entries[_entryId].uri = tempStorage[2];
                entries[_entryId].approved = tempStorage[3];

                    // update maxId
                if (entries[_entryId].id > maxId) {
                    maxId = entries[_entryId].id;
                }
            }
            // console.logWhereInline("checkState 2".green);

            // 1

            let sequential = true;
            for (let i = 0; i < maxEntryLength; i++) {
                // console.logWhereInline(`checkState 2A; i=${i}`.green);
                if (entries[i]._entryId != i) {
                    sequential = false;
                    break;
                }
            }
            await expect(sequential).to.equal(true);

            // console.logWhereInline("checkState 3".green);

            // 2

            // check each entry for consistency with its index lists
            for (let _entryId = 1; _entryId < maxEntryLength; _entryId += 1) {
                // console.logWhereInline(`checkState 4A; _entryId=${_entryId}`.green);

                // indexesWithId is consistent with this entry IFF the index of the entry
                // is present in indexesWithId[id] 
                let indexesWithIdConsistent = false;
                let id = entries[_entryId].id;
                indexesWithId[id] = [];
                maxIndexLength = await hardhatTestERC1155C.debug_get_indexesWithId_length(id);
                // console.logWhereInline(`checkState 4A0; maxIndexLength = ${maxIndexLength}`.yellow);
                for (let _indexId = 0; _indexId < maxIndexLength; _indexId++) {
                    // console.logWhereInline(`checkState 4A1; id, _indexId = ${id}, ${_indexId}`.green);
                    indexesWithId[id][_indexId] = await(
                        hardhatTestERC1155C.debug_get_indexesWithId(id, _indexId)
                    );
                    // console.logWhereInline(`checkState 4A2; indexesWithId[id][_indexId], _entryId = ${indexesWithId[id][_indexId]}, ${_entryId}`.green);
                    if (indexesWithId[id][_indexId] == _entryId) {
                        indexesWithIdConsistent = true;
                        break;
                    }
                }
                // console.logWhereInline(`checkState 4B; _entryId=${_entryId}`.green);


                // indexesWithUri is consistent with this entry IFF the index of the entry
                // is present in indexesWithUri[uri]
                let indexesWithUriConsistent = false;
                let uri = entries[_entryId].uri;
                indexesWithUri[uri] = [];
                maxIndexLength = await hardhatTestERC1155C.debug_get_indexesWithUri_length(uri);
                // console.logWhereInline(`checkState 4B0; maxIndexLength = ${maxIndexLength}`.yellow);
                for (let _indexId = 0; _indexId < maxIndexLength; _indexId++) {
                    // console.logWhereInline(`checkState 4B1; uri, _indexId = ${uri}, ${_indexId}`.yellow);
                    // console.logWhereInline(`checkState 4B1a; indexesWithUri[uri] = ${indexesWithUri[uri]}`.red);
                    indexesWithUri[uri][_indexId] = await(
                        hardhatTestERC1155C.debug_get_indexesWithUri(uri.toString(), _indexId)
                    );
                    // console.logWhereInline(`checkState 4B2; indexesWithUri[uri][_indexId], _entryId = ${indexesWithUri[uri][_indexId]}, ${_entryId}`.green);
                    if (indexesWithUri[uri][_indexId] == _entryId) {
                        indexesWithUriConsistent = true;
                        break;
                    }
                }
                // console.logWhereInline(`checkState 4C; _entryId=${_entryId}`.green);

                // console.logWhereInline(`checkState 4C; indexesWithIdConsistent=${indexesWithIdConsistent}`.yellow);
                // console.logWhereInline(`checkState 4C; indexesWithUriConsistent=${indexesWithUriConsistent}`.yellow);
                await expect(indexesWithIdConsistent).to.equal(true);
                await expect(indexesWithUriConsistent).to.equal(true);
                await expect(await 
                    hardhatTestERC1155C.debug_get_indexWithIdUri(
                        await hardhatTestERC1155C.get_bytes32hash(id, uri)
                )).to.equal(_entryId);
                // console.logWhereInline(`checkState 4D; _entryId=${_entryId}`.green);

                // 3

                if (_entryId != 0) {
                    expect(uri).to.not.equal("");
                }
            }

        }

        const checkERC1155MultiUri_UserUpgradeableStateInvariants = async() => {
            
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
                // if (!(await hardhatTestERC1155C.exists(id))) {
                //     await expect( await
                //         hardhatTestERC1155C.uri(id)
                //     ).to.equal("");
                // }

                // 2
                if ((await hardhatTestERC1155C.exists(id))) {
                    await expect( await
                        hardhatTestERC1155C.uri(id)
                    ).to.not.equal("");
                }

                // 3
                if (
                    await hardhatTestERC1155C.totalSupply(id) == 1
                    && await hardhatTestERC1155C.cannotMintMore(id)
                ) {
                    expect(await hardhatTestERC1155C.isPermanentlyUnique(id))
                    .to.equal(true);
                }

                // 4
                else if (await hardhatTestERC1155C.isPermanentlyUnique(id)) {
                    expect(await hardhatTestERC1155C.totalSupply(id))
                    .to.equal(1);
                    expect(await hardhatTestERC1155C.cannotMintMore(id))
                    .to.equal(true);
                }
            }
        }

        const checkStateInvariants = async () => {
            checkERC1155MultiUri_UserUpgradeableStateInvariants();
            checkModeratedUriStateInvariants();
        }

        // Fixtures can return anything you consider useful for your tests
        return { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 };
    }

    /// Tests from ModeratedUris
    it("----------------- ModeratedUris tests -----------------", async function () {
        expect(true).to.equal(true);
    });
    it("[C-1] Sets dev address as default admin", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        console.logWhereInline(`[C-1] 1; owner.address = ${owner.address}`);
        await expect(await 
            hardhatTestERC1155C.hasRole(
                await hardhatTestERC1155C.bytesToRoles("DEFAULT_ADMIN_ROLE"),
                owner.address
            )
        ).to.equal(true);
        console.logWhereInline(`[C-1] 2`);
        await checkStateInvariants();
    });
    it(`[C-2] Sets entry 0 to default "null" values`, async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        if (true) {
            let entries = []; 
            let _entryId = 0;
            entries[_entryId] = {};
            entries[_entryId] = await getEntry(_entryId);
            expect(entries[0]._entryId).to.equal(0);
            expect(entries[0].id).to.equal(0);
            expect(entries[0].uri).to.equal("");
            expect(entries[0].approved).to.equal(false);
        }
        await checkStateInvariants();
    });
    it(`[C-3] Populates entries succesfully`, async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await populateEntries(25);
        await checkStateInvariants();
    });
    it(`[C-4] Gives the correct response with isMetadataApprovedForAll function`, async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await populateEntries(25);
        let entries = [];
        let approvedEntriesPartitionedByUri = [];
        let maxEntryLength = await hardhatTestERC1155C.debug_get_entries_length();
        // get entries
        for (let _entryId = 1; _entryId < maxEntryLength; _entryId++) {
            entries[_entryId] = {};
            entries[_entryId] = await getEntry(_entryId);

            // // get entries partitioned
            // let uri = entries[_entryId].uri;
            // let approved = entries[_entryId].approved;
            // if (!approvedEntriesPartitionedByUri[uri]) {
            //     approvedEntriesPartitionedByUri[uri] = [];
            // }
            // if (approved) {
            //     approvedEntriesPartitionedByUri[uri].push(entries[_entryId]);
            // }
        }
        // console.logWhereInline(`[A-4] 1`.green);
        
        for (let _entryId = 1; _entryId < maxEntryLength; _entryId++) {
            let uri;
            let id;
            let approved;
            if (entries[_entryId].id != 0) { continue; }
            uri = entries[_entryId].uri;
            id = entries[_entryId].id;
            approved = entries[_entryId].approved;
            let result = await hardhatTestERC1155C.isMetadataApprovedForAll(uri);

            console.logWhereInline(`[A-4] 1A; uri = ${uri}, id = ${id}, approved = ${approved}, result = ${result}`.green);
            expect(result).to.equal(approved);
        }
        await checkStateInvariants();
    });
    it(`[C-5] Gives the correct response with isMetadataApprovedForId function`, async function () {
        console.logWhereInline(`[C-5] 0`.green);
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        console.logWhereInline(`[C-5] 1`.green);
        
        // 5 minutes - test only requires a timeout interval this long when `entryCount` is set 
        // to over 1000, whereas 100 should usually be sufficient and finishes in ~10 seconds.  
        this.timeout(300000); 
        let entryCount = 100;
        await populateEntries(entryCount);
        let entries = [];
        let approvedEntriesPartitionedByUri = [];
        let maxEntryLength = await hardhatTestERC1155C.debug_get_entries_length();
        // get entries
        for (let _entryId = 1; _entryId < maxEntryLength; _entryId++) {
            entries[_entryId] = {};
            entries[_entryId] = await getEntry(_entryId);
        }
        
        // get the uris which have global entries
        let globalResults = {};
        for (let _entryId = 1; _entryId < maxEntryLength; _entryId++) {
            let uri;
            let id;
            let approved;
            if (entries[_entryId].id != 0) { continue; }
            uri = entries[_entryId].uri;
            id = entries[_entryId].id;
            approved = entries[_entryId].approved;
            globalResults[uri] = await hardhatTestERC1155C.isMetadataApprovedForAll(uri);

            expect(globalResults[uri]).to.equal(approved);
        }

        // if a uri has an approved global entry, that takes precedence
        for (let _entryId = 1; _entryId < maxEntryLength; _entryId++) {
            let uri;
            let id;
            let approved;
            let result;
            uri = entries[_entryId].uri;
            id = entries[_entryId].id;
            approved = entries[_entryId].approved;
            if (globalResults[uri] == true) {
                approved = true;
            }
            result = await hardhatTestERC1155C.isMetadataApprovedForId(id, uri);

            expect(result).to.equal(approved);
        }
        await checkStateInvariants();
    });

    /// Tests from ERC1155MultiUri_UserUpgradeable
    it("----------------- ERC1155MultiUti_UserUpgradeable tests -----------------", async function () {
		expect(true).to.equal(true);
	});
    it("[B-1] Fails to update metadata of ID not owned by user", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithURI(
            addr2.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.connect(addr1).safeUpdateURI(
            "uri",
            addr2.address,
            10
        )).to.be.revertedWith("ERC1155MultiURI_UserUpgradeable: caller is not owner nor approved");
        console.logWhereInline("here1");
        await checkStateInvariants();
    });
    it("[B-2] Fails to update metadata of that is not permanently unique", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.connect(addr1).safeUpdateURI(
            "uri",
            addr1.address,
            10
        )).to.be.revertedWith("Can only change URI on a token that is permanently unique");
        await checkStateInvariants();
    });
    it("[B-3] Allows updating of metadata of a permanently unique NFT, by its owner", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.connect(addr1).safeUpdateURI(
            "uri",
            addr1.address,
            10
        )).to.not.be.reverted;
        await checkStateInvariants();
    });
    it("[B-4] Fails to mint a permanently unique NFT", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.revertedWith("Token is non-mintable");
        await expect(hardhatTestERC1155C.mintWithoutURI(
            addr1.address,
            10,
            1,
            0x0
        )).to.be.revertedWith("Token is non-mintable");
        await checkStateInvariants();
    });
    it("[B-5] Does not mark a multiply-minted or unminted locked NFT as permanently unique", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.lockMinting(
            10
        )).to.be.not.reverted;
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            20,
            2,
            0x0,
            "first uri"
        )).to.not.be.reverted;
        await expect(hardhatTestERC1155C.lockMinting(
            20
        )).to.be.not.reverted;
        await expect(await hardhatTestERC1155C.isPermanentlyUnique(
            20
        )).to.equal(false);
        await expect(await hardhatTestERC1155C.isPermanentlyUnique(
            10
        )).to.equal(false);
        await checkStateInvariants();
    });
    it("[B-6] Does not mark a newly-minted NFT as permanently unique", async function () {
        const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.not.be.reverted;
        await expect(await hardhatTestERC1155C.isPermanentlyUnique(
            10
        )).to.equal(false);
        await checkStateInvariants();
    });

	
	/// Tests from ERC1155MultiUri
    it("------------------------- ERC1155MultiUti tests -------------------------", async function () {
		expect(true).to.equal(true);
	});
	it("[A-1] Mints new NFT with non-empty metadata", async function () {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "first uri"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it("[A-2] Fails to mint a new NFT with empty metadata", async function () {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            ""
        )).to.be.revertedWith("Empty string is not a valid metadata URI");
        await checkStateInvariants();
	});
	it("[A-3] Fails to mint an existing NFT with metadata", async function() {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await hardhatTestERC1155C.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            20,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it("[A-4] Mints existing NFT without metadata", async function () {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await hardhatTestERC1155C.mintWithURI(
            addr1.address,
            10,
            1,
            0x0,
            "non-empty"
        );
        await expect(hardhatTestERC1155C.mintWithoutURI(
            addr1.address,
            10,
            1,
            0x0,
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
	it(`[A-5] Fails to mint a new NFT without metadata`, async function() {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155C.mintWithoutURI(
            addr1.address,
            30,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
	});

    it(`[A-6] Changes URI of an id to non-empty metadata`, async function() {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(await hardhatTestERC1155C.setURI(
            30,
            "non-empty 0"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});
    it(`[A-7] Changes the URI of ID 0`, async function() {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(await hardhatTestERC1155C.setURI(
            0,
            "non-empty 1"
        )).to.be.not.reverted;
        await checkStateInvariants();
	});

	it("[A-8] Fails to mint ID 0 with metadata", async function () {
		const { TestERC1155C, hardhatTestERC1155C, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
		await expect(hardhatTestERC1155C.mintWithURI(
            addr1.address,
            0,
            1,
            0x0,
            "non-empty"
        )).to.be.reverted;
        await checkStateInvariants();
	});
    it("[A-9] Fails to mint ID 0 without metadata", async function () {
		const { TestERC1155MultiUri_UserUpgradeable, hardhatTestERC1155C, checkStateInvariants, owner, addr1, addr2 } = await loadFixture(deployTestERC1155MultiUri_UserUpgradeableFixture);
        await expect(hardhatTestERC1155C.mintWithoutURI(
            addr1.address,
            0,
            1,
            0x0
        )).to.be.reverted;
        await checkStateInvariants();
    });
});