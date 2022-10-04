// PASSING as of 2022-Sep-22

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

describe("ModeratedUris", function () {
    async function deployModeratedUrisFixture() {
        // console.logWhereInline("inFixture 1".green);

        const [owner, addr1, addr2] = await ethers.getSigners();
        const ModeratedUris = await ethers.getContractFactory("ModeratedUris");
        let hardhatModeratedUris = await ModeratedUris.deploy();
        // console.logWhereInline("inFixture 2".green);
        await hardhatModeratedUris.initialize();
        // console.logWhereInline("inFixture 3".green);
        let addresses = [];
        addresses[0] = "0x0000000000000000000000000000000000000000";
        for (let i = 1; i <= 50; i++) {
            addresses[i] = generateNewAddress();
            // console.logWhereInline(addresses[i]);
        }
        // console.logWhereInline("inFixture 4".green);
        

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
                    await hardhatModeratedUris.approveMetadataForAll(randUri);
                }
                else if (randApproved) {
                    await hardhatModeratedUris.approveMetadataForId(randId, randUri);
                }
                else if (randId % 2 == 0) {
                    await hardhatModeratedUris.unapproveMetadataForAll(randUri);
                }
                else {
                    await hardhatModeratedUris.unapproveMetadataForId(randId, randUri);
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
                    await hardhatModeratedUris.approveMetadataForAll(randUri);
                }
                else if (randApproved) {
                    await hardhatModeratedUris.approveMetadataForId(randId, randUri);
                }
                else if (randId % 2 == 0) {
                    await hardhatModeratedUris.unapproveMetadataForAll(randUri);
                }
                else {
                    await hardhatModeratedUris.unapproveMetadataForId(randId, randUri);
                }
                // console.logWhereInline(`populateEntries 1A; i=${i}, uri=${entries[i].uri}`.green);
            } 
            // console.logWhereInline("populateEntries 3".green);
        }

        const getEntry = async (_entryId) => {
            let tempStorage = await hardhatModeratedUris.debug_get_entry(_entryId);
            let entry = {};
            entry._entryId = tempStorage[0];
            entry.id = tempStorage[1];
            entry.uri = tempStorage[2];
            entry.approved = tempStorage[3];
            return entry;
        }

        const checkStateInvariants = async () => {

            // 1: each entry should be in sequential order, with _entryId matching its order
            // 2: indexWithIdUri, indexesWithUri, indexesWithId, and Entries must be consistent
            // 3: each entry other than 0 should have non-empty uri

            let maxId = 0;
            let maxEntryLength = await hardhatModeratedUris.debug_get_entries_length();
            console.logWhereInline(`checkState 0: length: ${maxEntryLength}`.yellow);
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
                let tempStorage = await hardhatModeratedUris.debug_get_entry(_entryId);
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
                maxIndexLength = await hardhatModeratedUris.debug_get_indexesWithId_length(id);
                // console.logWhereInline(`checkState 4A0; maxIndexLength = ${maxIndexLength}`.yellow);
                for (let _indexId = 0; _indexId < maxIndexLength; _indexId++) {
                    // console.logWhereInline(`checkState 4A1; id, _indexId = ${id}, ${_indexId}`.green);
                    indexesWithId[id][_indexId] = await(
                        hardhatModeratedUris.debug_get_indexesWithId(id, _indexId)
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
                maxIndexLength = await hardhatModeratedUris.debug_get_indexesWithUri_length(uri);
                // console.logWhereInline(`checkState 4B0; maxIndexLength = ${maxIndexLength}`.yellow);
                for (let _indexId = 0; _indexId < maxIndexLength; _indexId++) {
                    // console.logWhereInline(`checkState 4B1; uri, _indexId = ${uri}, ${_indexId}`.yellow);
                    // console.logWhereInline(`checkState 4B1a; indexesWithUri[uri] = ${indexesWithUri[uri]}`.red);
                    indexesWithUri[uri][_indexId] = await(
                        hardhatModeratedUris.debug_get_indexesWithUri(uri.toString(), _indexId)
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
                    hardhatModeratedUris.debug_get_indexWithIdUri(
                        await hardhatModeratedUris.get_bytes32hash(id, uri)
                )).to.equal(_entryId);
                // console.logWhereInline(`checkState 4D; _entryId=${_entryId}`.green);

                // 3

                if (_entryId != 0) {
                    expect(uri).to.not.equal("");
                }
            }

            


        }

        // Fixtures can return anything you consider useful for your tests
        return { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 };
    }

    /// Tests from ModeratedUris
    it("----------------- ModeratedUris tests -----------------", async function () {
        expect(true).to.equal(true);
    });
    it("[A-1] Sets dev address as default admin", async function () {
        const { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployModeratedUrisFixture);
        await expect(await 
            hardhatModeratedUris.hasRole(
                await hardhatModeratedUris.bytesToRoles("DEFAULT_ADMIN_ROLE"),
                owner.address
            )
        ).to.equal(true);
        await checkStateInvariants();
    });
    it(`[A-2] Sets entry 0 to default "null" values`, async function () {
        const { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployModeratedUrisFixture);
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
    it(`[A-3] Populates entries succesfully`, async function () {
        const { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployModeratedUrisFixture);
        await populateEntries(25);
        await checkStateInvariants();
    });
    it(`[A-4] Gives the correct response with isMetadataApprovedForAll function`, async function () {
        const { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployModeratedUrisFixture);
        await populateEntries(25);
        let entries = [];
        let approvedEntriesPartitionedByUri = [];
        let maxEntryLength = await hardhatModeratedUris.debug_get_entries_length();
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
            let result = await hardhatModeratedUris.isMetadataApprovedForAll(uri);

            console.logWhereInline(`[A-4] 1A; uri = ${uri}, id = ${id}, approved = ${approved}, result = ${result}`.green);
            expect(result).to.equal(approved);
        }
        await checkStateInvariants();
    });
    it(`[A-5] Gives the correct response with isMetadataApprovedForId function`, async function () {
        const { ModeratedUris, hardhatModeratedUris, checkStateInvariants, getEntry, populateEntries, owner, addr1, addr2 } = await loadFixture(deployModeratedUrisFixture);
        // 5 minutes - test only requires a timeout interval this long when `entryCount` is set 
        // to over 1000, whereas 100 should usually be sufficient and finishes in ~10 seconds.  
        this.timeout(300000); 
        let entryCount = 500;
        await populateEntries(entryCount);
        let entries = [];
        let approvedEntriesPartitionedByUri = [];
        let maxEntryLength = await hardhatModeratedUris.debug_get_entries_length();
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
            globalResults[uri] = await hardhatModeratedUris.isMetadataApprovedForAll(uri);

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
            result = await hardhatModeratedUris.isMetadataApprovedForId(id, uri);

            expect(result).to.equal(approved);
        }
        await checkStateInvariants();
    });
});

