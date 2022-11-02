const testEnabled = true

if (!testEnabled) {
	return;
}

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { BigNumber } = require("@ethersproject/bignumber");


describe("TypeConversions contract", function () {
	async function TypeConversionsFixture() {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const TypeConversions = await ethers.getContractFactory("testTypeConversions");
		const hardhatdeploy = await TypeConversions.deploy();
		
		const maxUint = BigNumber.from("115792089237316195423570985008687907853269984665640564039457584007913129639935");
		const maxInt = BigNumber.from("57896044618658097711785492504343953926634992332820282019728792003956564819967");
		const minInt = BigNumber.from("-57896044618658097711785492504343953926634992332820282019728792003956564819967");
				
		
		let _sampleAddress = "0x5b38da6a701c568545dcfcb03fcb875f56beddc4";
		let _sampleAddressfrombyte = "0x0000000000000000000000000000000000000000"
		let _sampleUint = 0;
		let _sampleInt = -1;
		let _sampleBool = true;
		let _sampleBool2 = false
		let _sampleBytes = "0x0000000000000000000000000000000000000000000000000000000000000064";
		let _sampleBytes2 = "0x616365"
		let _sampleString = "ace";
		let _sampleByte32 = "0x6163650000000000000000000000000000000000000000000000000000000000";
		let _sample2Bytes32 = "0x0000000000000000000000000000000000000000000000000000000000000064";

	
		return { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleAddressfrombyte,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			maxUint,
			maxInt,
			minInt
		       };
}

	it("[A-1]should equal to `true' string from boolean", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool,
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool)).to.equal("true");
	})
	
	it("[A-2]should equal to `false' string from boolean", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool2,
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool2)).to.equal("false");
	})
	
	it("[B-1]should equal to `0` in string from uint", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleUint,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToString = await expect(await hardhatdeploy.tryUintToString(_sampleUint)).to.equal("0");
	})
	
	it("[B-2]should equal to maxUint in string from uint", async function () {
		const { TypeConversions,
			hardhatdeploy,
			maxUint
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToString = await expect(await hardhatdeploy.tryUintToString(maxUint)).to.equal(maxUint);
	})
	
	it("[C-1]should equal to minInt in string from int", async function () {
		const { TypeConversions,
			hardhatdeploy,
			minInt
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToString = await expect(await hardhatdeploy.tryIntToString(minInt)).to.equal(minInt);
	})
	
	it("[C-2]should equal to maxInt in string from int", async function () {
		const { TypeConversions,
			hardhatdeploy,
			maxInt
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToString = await expect(await hardhatdeploy.tryIntToString(maxInt)).to.equal(maxInt);
	})
	
	
	it("[D-1]should equal to `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4` in string from address", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddressfrombyte,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToString = await expect(await hardhatdeploy.tryAddressToString(_sampleAddressfrombyte)).to.equal(_sampleAddressfrombyte);
	})	
	
	it("[D-2]should equal to `0x0000000000000000000000000000000000000000` in string from address", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToString = await expect(await hardhatdeploy.tryAddressToString(_sampleAddress)).to.equal(_sampleAddress);
	})
	
	it("[E-1]should equal to `ace` in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString(_sampleByte32)).to.equal("ace");
	})
	
	it("[E-2]should equal to `test` in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString("0x7465737400000000000000000000000000000000000000000000000000000000")).to.equal("test");
	})
	
	it("[E-3]should equal to `` in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString("0x0000000000000000000000000000000000000000000000000000000000000000")).to.equal("");
	})
	
	it("[F-1]should equal to true in boolean from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool(_sampleBytes)).to.equal(true);
	})
	
	it("[F-2]should equal to false in boolean from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool("0x")).to.equal(false);
	})

	it("[G-1.1]should equal to 100 uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint(_sampleBytes)).to.equal(100);
	})
	
	it("[G-1.2]should convert 100 uint to 0x0000000000000000000000000000000000000000000000000000000000000064", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes(100)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000064");
	})
	
	it("[G-2.1]should equal to 1 uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint(0x0000000000000000000000000000000000000000000000000000000000000001)).to.equal(1);
	})
	
	it("[G-2.2]should convert 1 uint to 0x0000000000000000000000000000000000000000000000000000000000000001", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes(1)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
	})

	
	it("[G-3.1]should equal to 0 uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint("0x0000000000000000000000000000000000000000000000000000000000000000")).to.equal(0);
	})
	
	
	it("[G-3.2]should convert 0 uint to 0x0000000000000000000000000000000000000000000000000000000000000000", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleUint,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes(_sampleUint)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
	})

	it("[H-1.1]should equal to 100 in integers from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToInt = await expect(await hardhatdeploy.tryBytesToInt(_sampleBytes)).to.equal(100);
	})
	
	it("[H-1.2]should convert 100 int to 0x0000000000000000000000000000000000000000000000000000000000000064", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(100)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000064");
	})
	
	it("[H-2.1]should equal to 1 in integers from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,

		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToInt = await expect(await hardhatdeploy.tryBytesToInt(0x0000000000000000000000000000000000000000000000000000000000000001)).to.equal(1);
	})
	
	it("[H-2.2]should convert 1 int to 0x0000000000000000000000000000000000000000000000000000000000000001", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(1)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
	})
	
	it("[H-3.1]should equal to -1 in integers from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToInt = await expect(await hardhatdeploy.tryBytesToInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")).to.equal(-1);
	})
	
	it("[H-3.2]should convert -1 int to 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(-1)).to.equal("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
	})

	it("[I-1.1]should equal to 0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa in address from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToAddress = await expect(await hardhatdeploy.tryBytesToAddress("0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa")).to.equal("0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa");
	})
	
	it("[I-1.2]should convert 0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa address to 0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToBytes = await expect(await hardhatdeploy.tryAddressToBytes("0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa")).to.equal("0x0ab4BbB18a038035E5eB8B0a2232Ec7c80e704aa");
	})
	
	it("[I-2.1]should equal to 0x3B7E3561bc20bACF5926270f3E0858c67E67DD70 in address from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToAddress = await expect(await hardhatdeploy.tryBytesToAddress("0x3B7E3561bc20bACF5926270f3E0858c67E67DD70")).to.equal("0x3B7E3561bc20bACF5926270f3E0858c67E67DD70");
	})

	it("[I-2.2]should convert 0x3B7E3561bc20bACF5926270f3E0858c67E67DD70 address to 0x3B7E3561bc20bACF5926270f3E0858c67E67DD70 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToBytes = await expect(await hardhatdeploy.tryAddressToBytes("0x3B7E3561bc20bACF5926270f3E0858c67E67DD70")).to.equal("0x3B7E3561bc20bACF5926270f3E0858c67E67DD70");
	})

	it("[J-1.1]should equal to 0xA000000000000000000000000000000000000000000000000000000000000064 bytes32 from 0xA000000000000000000000000000000000000000000000000000000000000064 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
			_sample2Bytes32,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBytes32 = await expect(await hardhatdeploy.tryBytesToBytes32("0xA000000000000000000000000000000000000000000000000000000000000064")).to.equal("0xA000000000000000000000000000000000000000000000000000000000000064");
	})
	
	it("[J-1.2]should convert 0xA000000000000000000000000000000000000000000000000000000000000064 bytes32 to 0xA000000000000000000000000000000000000000000000000000000000000064 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const trybytes32ToBytes = await expect(await hardhatdeploy.trybytes32ToBytes("0xA000000000000000000000000000000000000000000000000000000000000064")).to.equal("0xA000000000000000000000000000000000000000000000000000000000000064");
	})

	it("[J-2.1]should equal to 0x6163650000000000000000000000000000000000000000000000000000000000 bytes32 from 0x616365 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleByte32,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBytes32 = await expect(await hardhatdeploy.tryBytesToBytes32(_sampleBytes2)).to.equal(_sampleByte32);
	})
	
	it("[J-2.2]should convert 0x6163650000000000000000000000000000000000000000000000000000000000 bytes32 to 0x6163650000000000000000000000000000000000000000000000000000000000 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleByte32,
		      } = await loadFixture(TypeConversionsFixture);
		const trybytes32ToBytes = await expect(await hardhatdeploy.trybytes32ToBytes(_sampleByte32)).to.equal(_sampleByte32);
	})

	it("[K-1.1]should equal to 'ace' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString(_sampleBytes2)).to.equal("ace");
	})
	
	it("[K-1.2]should convert 'ace' to 0x616365", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleString,
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes(_sampleString)).to.equal(_sampleBytes2);
	})
	
	it("[K-2.1]should equal to 'test' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString("0x74657374")).to.equal("test");
	})
	
	it("[K-2.2]should convert 'test' to 0x74657374", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleString,
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes('test')).to.equal('0x74657374');
	})
	
	it("[K-3.1]should equal to '' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString("0x")).to.equal("");
	})
	
	it("[K-3.2]should convert '' to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes('')).to.equal("0x");
	})

	it("[L-1]should convert bool to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBoolToBytes = await hardhatdeploy.tryBoolToBytes(_sampleBool);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool(tryBoolToBytes)).to.equal(true);
	})

	it("[L-2]should convert bool to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool2,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBoolToBytes = await expect(await hardhatdeploy.tryBoolToBytes(_sampleBool2)).to.equal("0x");
	})

	// Conor's tests

})
