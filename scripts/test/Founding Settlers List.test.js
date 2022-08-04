const {
	time,
	loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
var Accounts = require('web3-eth-accounts');
var accounts = new Accounts('ws://localhost:8546');

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

			let addresses;
			addresses[0] = "0x0000000000000000000000000000000000000000";
			for (let i = 1; i <= 50; i++) {
				addresses[i] = await web3.eth.accounts.create((((i + 10 ** 4) ** 5) % (10 ** 11)).toString()).address;
			}

			let ops = 3;
			let states = 2;
			let elements = 4;

			let opsOrders;
			let statesOrders;
			let elementsOrders;

			// taken from https://stackoverflow.com/questions/9960908/permutations-in-javascript
			const permutator = (inputArr) => {
				let result = [];

				const permute = (arr, m = []) => {
					if (arr.length === 0) {
						result.push(m);
					} else {
						for (let i = 0; i < arr.length; i++) {
							let curr = arr.slice();
							let next = curr.splice(i, 1);
							permute(curr.slice(), m.concat(next));
						}
					}
				}

				permute(inputArr);

				return result;
			}

			const initializeAddresses = async () => {
				hardhatFoundingSettlersNftMint = await FoundingSettlersNftMint.deploy();
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
				let temp = addresses.length + 1;
				addresses[temp] = web3.eth.accounts.create((((temp + 10 ** 4) ** 5) % (10 ** 11)).toString()).address;
				return addresses[temp];
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
				expect(invar2).equal.to(true);
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
				expect(invar3).equal.to(true);
				let invar4 = (await hardhatFoundingSettlersNftMint.addresses.listInv[returnNonexistingElement] == 0);
				expect(invar4).equal.to(true);
				let invar5 = true;
				for (let i = 1; i <= tempLength; i++) {
					if (tempAddresses[i] == addresses[0]) {
						invar5 = false;
						break;
					}
				}
				expect(invar5).equal.to(true);
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
				expect(invar6).equal.to(true);
			};


			// opsOrders = permutator([...Array(ops+1).keys()].slice(1));
			// statesOrders = permutator([...Array(states+1).keys()].slice(1));
			// elementsOrders = permutator([...Array(elements+1).keys()].slice(1));

			//------

			for (let j = 0; j < ops; j++) {
				let op = j;
				for (let k = 0; k < states; k++) {
					let state = k;
					for (let l = 0; l < elements; l++) {
						let elementType = l;
						let tempAddress;
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
							continue;
						}

						if (state == 0) { // make list empty
							makeListEmpty();
						}
						else if (state == 1) { // make list non-empty
							makeListNonEmpty();
						}
						else {
							continue;
						}

						if (op == 0) { // initialize list
							initializeAddresses();
							let tempAddresses;
							for (let i = 1; i <= 5; i++) {
								tempAddresses[i] = await hardhatFoundingSettlersNftMint.addresses.list[i]
								expect(tempAddress[i] != addresses[0] && tempAddress[i] != tempAddress[i + 1]).to.equal(true);
							}
						}
						else if (op == 1) { // add address
							addAddress(tempAddress);
							let tempIndex = await hardhatFoundingSettlersNftMint.addresses.listInv[tempAddress];
							expect(await hardhatFoundingSettlersNftMint.addresses.list[tempIndex]).to.equal(tempAddress);
						}
						else if (op == 2) { // remove address
							if (state == 0) {
								expect(removeAddress(tempAddress)).to.equal(false);
							}
							else {
								expect(removeAddress(tempAddress)).to.equal(true);
							}
						}
						else {
							continue;
						}
						expect(InvariantsAreSatisfied()).to.equal(true);
					}
				}
			}
		});
});