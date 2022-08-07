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

// adding new method console.logWhere that is console.log but also prints line numbers of the resulting logs
// adapted from https://stackoverflow.com/questions/45395369/how-to-get-console-log-line-numbers-shown-in-nodejs
const addConsoleLogWhere = () => {
	console.logWhere = console.log;

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
			originalMethod.apply(console, [...args, '\n', `  at ${initiator}`]);
		};
	});
};
addConsoleLogWhere();



//

describe("Founding Settlers List", async function () {
	it("Deployment should " +
		"perform each of the following operations and check that the invariants hold and the result is as expected:\n" +
		"\tInitialize the address list correctly\n" +
		"\tAdd an address\n" +
		"\tRemove and address\n" +
		".\n" +
		"The following states of the list should be checked:\n" +
		"\tEmpty list\n" +
		"\tNon-empty list\n" +
		".\n" +
		"The following elements should be tried:\n" +
		"\tExists in the list\n" +
		"\tDoesn't exist in the list\n" +
		"\tthe zero address\n" +
		"\tbad input\n", async function () {
			const [owner] = await ethers.getSigners();

			const FoundingSettlersNftMint = await ethers.getContractFactory("SettlersTickets");

			let hardhatFoundingSettlersNftMint = await FoundingSettlersNftMint.deploy();

			let addresses = [];
			addresses[0] = "0x0000000000000000000000000000000000000000";

			const generateNewAddress = async () => {
				var id = crypto.randomBytes(32).toString('hex');
				var privateKey = "0x" + id;
				//console.logWhere("SAVE BUT DO NOT SHARE THIS:", privateKey);

				var wallet = new ethers.Wallet(privateKey);
				//console.logWhere("Address: " + wallet.address);
				addresses[addresses.length] = wallet.address;
				// console.logWhere(`
				// 	wallet.address = ${wallet.address} , 
				// 	addresses[addresses.length - 1] = ${addresses[addresses.length - 1]}`
				// );
				return addresses[addresses.length - 1];
			}
			for (let i = 1; i <= 50; i++) {
				generateNewAddress();
			}

			let ops = 3;
			let states = 2;
			let elements = 4;

			let opsOrders;
			let statesOrders;
			let elementsOrders;

			// // taken from https://stackoverflow.com/questions/9960908/permutations-in-javascript
			// const permutator = (inputArr) => {
			// 	let result = [];

			// 	const permute = (arr, m = []) => {
			// 		if (arr.length === 0) {
			// 			result.push(m);
			// 		} else {
			// 			for (let i = 0; i < arr.length; i++) {
			// 				let curr = arr.slice();
			// 				let next = curr.splice(i, 1);
			// 				permute(curr.slice(), m.concat(next));
			// 			}
			// 		}
			// 	}

			// 	permute(inputArr);

			// 	return result;
			// }

			console.logWhere(`cp`)
			const initializeAddresses = async () => {
				await hardhatFoundingSettlersNftMint.initList();
			};
			const addAddress = async (address) => {
				await hardhatFoundingSettlersNftMint.addAddress(address);
			};
			const removeAddress = async (address) => {
				await hardhatFoundingSettlersNftMint.removeAddress(address);
			};

			const makeListEmpty = async () => {
				let tempAddress = await hardhatFoundingSettlersNftMint.addresses.list[1]
				let runs = 0;
				for (; tempAddress != addresses[0]; runs++) {
					await hardhatFoundingSettlersNftMint.removeAddress(tempAddress);
					if (runs > 100) {
						break;
					}
				}
				expect(runs <= 100).equal.to(true);
			};
			const makeListNonEmpty = async () => {
				for (let i = 1; i <= 10; i++) {
					addAddress(addresses[i]);
				}
			};

			const returnExistingElement = async () => {
				let tempLength = await hardhatFoundingSettlersNftMint.addresses.length
				let n = Math.floor(
					Math.random() * tempLength + 1
				);
				return await hardhatFoundingSettlersNftMint.addresses.list[n];
			};
			const returnNonexistingElement = async () => {
				return await generateNewAddress();
			};
			const returnZeroAddress = async () => {
				return addresses[0];
			};
			const returnBadInput = async () => {
				return "bad_input";
			};

			// 	Invariants:
			//  *          ✓ (1) Each ID is a uint256
			//  *          ✓ (2) Each address in the list is associated with a unique ID 
			//  *          ✓ (3) Each ID other than ID 0 is associated with a unique address
			//  *          ✓ (4) An address that is not in the list maps to ID 0
			//  *          ✓ (5) All IDs from 1 to the length of the list map to an address that is not the zero address
			//  *          ✓ (6) All IDs greater than the length of the list and ID 0 map to the zero address 
			const InvariantsAreSatisfied = async () => {
				const invar1 = true; // invariant 1 is guaranteed at compile time 
				console.logWhere(`invar1=${invar1}`)
				let tempAddresses;
				let TempIndices;
				let tempLength = await hardhatFoundingSettlersNftMint.addresses.length;
				for (let i = 1; i <= tempLength; i++) {
					tempAddresses[i] = await hardhatFoundingSettlersNftMint.addresses.list[i];
					tempIndices[i] = await hardhatFoundingSettlersNftMint.addresses.listInv[tempAddresses[i]];
				}
				let invar2 = true;
				for (let i = 1; i <= tempLength; i++) {
					if (invar2 = false) {
						break;
					}
					for (let j = 1; j <= tempLength; j++) {
						if (tempAddresses[i] == tempAddresses[j] && i != j) {
							invar2 = false;
							break;
						}
					}
				}
				console.logWhere(`invar2=${invar2}`)
				expect(invar2).to.equal(true);
				let invar3 = true;
				for (let i = 1; i < tempLength; i++) {
					if (invar3 = false) {
						break;
					}
					// if (tempIndices[i] != i) {
					// 	break;
					// }
					for (let j = 1; j <= tempLength; j++) {
						if (tempIndices[i] == tempIndices[j] && i != j) {
							invar3 = false;
							break;
						}
					}
				}
				console.logWhere(`invar3=${invar3}`)
				expect(invar3).to.equal(true);
				let invar4 = (await hardhatFoundingSettlersNftMint.addresses.listInv[await returnNonexistingElement()] == 0);
				console.logWhere(`invar4=${invar4}`)
				expect(invar4).to.equal(true);
				let invar5 = true;
				for (let i = 1; i <= tempLength; i++) {
					if (tempAddresses[i] == addresses[0]) {
						invar5 = false;
						break;
					}
				}
				console.logWhere(`invar5=${invar5}`)
				expect(invar5).to.equal(true);
				let invar6 = true;
				if (await hardhatFoundingSettlersNftMint.addresses.list[0] != addresses[0]) {
					invar6 = false;
				}
				for (let i = tempLength + 1; i < tempLength + 50; i++) {
					if (await hardhatFoundingSettlersNftMint.addresses.list[i] != addresses[0]) {
						invar6 = false;
					}
					if (invar6 == false) {
						break;
					}
				}
				console.logWhere(`invar6=${invar6}`)
				expect(invar6).to.equal(true);
				return invar1 && invar2 && invar3 && invar4 && invar5 && invar6;
			};


			// opsOrders = permutator([...Array(ops+1).keys()].slice(1));
			// statesOrders = permutator([...Array(states+1).keys()].slice(1));
			// elementsOrders = permutator([...Array(elements+1).keys()].slice(1));

			//------

			console.logWhere(`cp2`);
			let trial = -1;
			let _trial;
			for (let j = 0; j < ops; j++) {
				let op = j;
				for (let k = 0; k < states; k++) {
					let state = k;
					for (let l = 0; l < elements; l++ /*() => {l++; trial++;}*/) {
						trial++;

						let elementType = l;
						_trial = ((op)*states + state)*elements + elementType; 
						console.logWhere(`trial:${trial}, _trial:${_trial}, op=${op}, state=${state}, elementType=${elementType}`)

						let tempAddress;
						console.logWhere(`cp3_${trial} op=${op}, state=${state}, elementType=${elementType}`);
						if (elementType == 0) { // use existing element (if list is not empty)
							if (await hardhatFoundingSettlersNftMint.addresses.length == 0) {
								continue;
							}
							else {
								tempAddress = returnExistingElement();
							}
						}
						else if (elementType == 1) { // use non-existing element
							tempAddress = returnNonexistingElement();
						}
						else if (elementType == 2) { // use zero address
							tempAddress = returnZeroAddress();
						}
						else if (elementType == 3) { // use bad input
							tempAddress = returnBadInput();
						}
						else {
							console.error(`elementType is ${elementType}, should be one of {0,1,2,3}`);
							break;
						}

						console.logWhere(`cp4_${trial} op=${op}, state=${state}, elementType=${elementType}`);
						if (state == 0) { // make list empty
							makeListEmpty();
						}
						else if (state == 1) { // make list non-empty
							makeListNonEmpty();
						}
						else {
							console.error(`state is ${state}, should be one of {0,1}`);
							break;
						}

						console.logWhere(`cp5_${trial} op=${op}, state=${state}, elementType=${elementType}`);
						if (op == 0) { // initialize list
							console.logWhere(`length=${await hardhatFoundingSettlersNftMint.addresses.length}`);
							for (let m = 0; m < 75; m++) {
								console.logWhere(`[${m}]=${await hardhatFoundingSettlersNftMint.addresses_list(m)}`);
							}
							await initializeAddresses();
							let tempAddresses = [];
							for (let i = 1; i <= 5; i++) {
								tempAddresses[i] = await hardhatFoundingSettlersNftMint.addresses_list(i);
							}
							for (let i = 1; i < 5; i++) { //comparing to element [i+1], so the last element cannot be considered
								// console.logWhere(`[${i}]=${tempAddresses[i]}, [0]=${addresses[0]}, [${i + 1}]=${tempAddresses[i + 1]}`);
								//console.logWhere(`expect ${tempAddresses[i] != addresses[0] && tempAddresses[i] != tempAddresses[i + 1]}`)
								expect(tempAddresses[i] != addresses[0] && tempAddresses[i] != tempAddresses[i + 1]).to.equal(true);
							}
						}
						else if (op == 1) { // add address
							addAddress(tempAddress);
							let tempIndex = await hardhatFoundingSettlersNftMint.addresses.listInv[tempAddress];
							//console.logWhere(`expect ${await hardhatFoundingSettlersNftMint.addresses.list[tempIndex] == tempAddress}`)
							expect(await hardhatFoundingSettlersNftMint.addresses.list[tempIndex]).to.equal(tempAddress);
						}
						else if (op == 2) { // remove address
							if (state == 0) {
								let removedSuccessfully = removeAddress(tempAddress);
								console.logWhere(`expect ${!removedSuccessfully}`)
								expect(removedSuccessfully).to.equal(false);
							}
							else {
								let removedSuccessfully = removeAddress(tempAddress);
								console.logWhere(`expect ${removedSuccessfully}`)
								expect(removedSuccessfully).to.equal(true);
							}
						}
						else {
							console.error(`op is ${op}, should be one of {0,1,2}`);
							break;
						}
						console.logWhere(`cp6_${trial} op=${op}, state=${state}, elementType=${elementType}`);
						let invarsSat = await InvariantsAreSatisfied();
						console.logWhere(`invarsSat=${invarsSat}`);
						expect(invarsSat).to.equal(true);
					}
				}
			}
		});
});