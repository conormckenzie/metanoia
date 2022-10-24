const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("TypeConversions contract", function () {
	async function TypeConversionsFixture() {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const TypeConversions = await ethers.getContractFactory("testTypeConversions");
		const hardhatdeploy = await TypeConversions.deploy();
		
		let _sampleAddress = "0x5b38da6a701c568545dcfcb03fcb875f56beddc4";
		let _sampleAddressfrombyte = "0x0000000000000000000000000000000000000000"
		let _sampleUint = 1;
		let _sampleInt = -1;
		let _sampleBool = true;
		let _sampleBool2 = false
		let _sampleBytes = "0x0000000000000000000000000000000000000000000000000000000000000064";
		let _sampleBytes2 = "0x616365"
		let _sampleString = "ace";
		let _sampleByte32 = "0x6163650000000000000000000000000000000000000000000000000000000000";
		let _sample2Bytes32 = "0x0000000000000000000000000000000000000000000000000000000000000064"

	
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
			_sample2Bytes32
		       };
}

	it("should equal to `true' string from boolean", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool,
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool)).to.equal("true");
	})
	
	it("should equal to `false' string from boolean", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool2,
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool2)).to.equal("false");
	})
	
	it("should equal to 1 in string from uint", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleUint,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToString = await expect(await hardhatdeploy.tryUintToString(_sampleUint)).to.equal("1");
	})
	
	it("should equal to 10 in string from uint", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToString = await expect(await hardhatdeploy.tryUintToString(10)).to.equal("10");
	})
	
	it("should equal to -1 in string from int", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleInt,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToString = await expect(await hardhatdeploy.tryIntToString(_sampleInt)).to.equal("-1");
	})
	
	it("should equal to 99999 in string from int", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToString = await expect(await hardhatdeploy.tryIntToString(99999)).to.equal("99999");
	})
	
	
	it("should equal to 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 in string from address", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddressfrombyte,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToString = await expect(await hardhatdeploy.tryAddressToString(_sampleAddressfrombyte)).to.equal(_sampleAddressfrombyte);
	})	
	
	it("should equal to 0x0000000000000000000000000000000000000000 in string from address", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToString = await expect(await hardhatdeploy.tryAddressToString(_sampleAddress)).to.equal(_sampleAddress);
	})
	
	it("should equal to ace in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString(_sampleByte32)).to.equal("ace");
	})
	
	it("should equal to test in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString("0x7465737400000000000000000000000000000000000000000000000000000000")).to.equal("test");
	})
	
	it("should equal to true in boolean from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool(_sampleBytes)).to.equal(true);
	})
	
	it("should equal to false in boolean from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool("0x")).to.equal(false);
	})

	it("should equal to 100 uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint(_sampleBytes)).to.equal(100);
	})
	
	it("should equal to 1 uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint("0x0000000000000000000000000000000000000000000000000000000000000001")).to.equal(1);
	})

/*	it("should equal to 100 in integers from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToInt = await expect(await hardhatdeploy.tryBytesToInt(_sampleBytes)).to.equal(100);
	})*/

	it("should equal to 0x0000000000000000000000000000000000000000 in address from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToAddress = await expect(await hardhatdeploy.tryBytesToAddress(_sampleBytes)).to.equal(_sampleAddressfrombyte);
	})
	
	it("should equal to 0x6163650000000000000000000000000000000000 in address from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddressfrombyte,
			_sampleBytes2
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToAddress = await expect(await hardhatdeploy.tryBytesToAddress(_sampleBytes2)).to.equal("0x6163650000000000000000000000000000000000");
	})

	it("should equal to 0x0000000000000000000000000000000000000000000000000000000000000064 from 0x0000000000000000000000000000000000000000000000000000000000000064", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes,
			_sample2Bytes32,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBytes32 = await expect(await hardhatdeploy.tryBytesToBytes32(_sampleBytes)).to.equal(_sample2Bytes32);
	})

	it("should equal to 0x6163650000000000000000000000000000000000000000000000000000000000 from 0x616365", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleByte32,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBytes32 = await expect(await hardhatdeploy.tryBytesToBytes32(_sampleBytes2)).to.equal(_sampleByte32);
	})

	it("should equal to 'ace' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString(_sampleBytes2)).to.equal("ace");
	})
	
	it("should equal to 'test' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString("0x74657374")).to.equal("test");
	})

/*	it("should convert bool to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBool,
		      } = await loadFixture(TypeConversionsFixture);
		const tryBoolToBytes = await hardhatdeploy.tryBoolToBytes(_sampleBool);
	})*/

	it("should convert 1 uint to 0x0000000000000000000000000000000000000000000000000000000000000001", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleUint,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes(_sampleUint)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
	})
	
	it("should convert 5 uint to 0x0000000000000000000000000000000000000000000000000000000000000005", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes("5")).to.equal("0x0000000000000000000000000000000000000000000000000000000000000005");
	})

	it("should convert 100 int to 0x0000000000000000000000000000000000000000000000000000000000000064", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(100)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000064");
	})
	
	it("should convert -1 int to 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", async function () {
		const { TypeConversions,
			hardhatdeploy,
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(-1)).to.equal("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
	})

	it("should convert 0x5b38da6a701c568545dcfcb03fcb875f56beddc4 address to 0x5b38da6a701c568545dcfcb03fcb875f56beddc4 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToBytes = await expect(await hardhatdeploy.tryAddressToBytes(_sampleAddress)).to.equal(_sampleAddress);
	})
	
	it("should convert 0x0000000000000000000000000000000000000000 address to 0x0000000000000000000000000000000000000000 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddressfrombyte,
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToBytes = await expect(await hardhatdeploy.tryAddressToBytes(_sampleAddressfrombyte)).to.equal(_sampleAddressfrombyte);
	})

	it("should convert 0x6163650000000000000000000000000000000000000000000000000000000000 bytes32 to 0x6163650000000000000000000000000000000000000000000000000000000000 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleByte32,
		      } = await loadFixture(TypeConversionsFixture);
		const trybytes32ToBytes = await expect(await hardhatdeploy.trybytes32ToBytes(_sampleByte32)).to.equal(_sampleByte32);
	})
	
	it("should convert 0x0000000000000000000000000000000000000000000000000000000000000064 bytes32 to 0x0000000000000000000000000000000000000000000000000000000000000064 bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sample2Bytes32,
		      } = await loadFixture(TypeConversionsFixture);
		const trybytes32ToBytes = await expect(await hardhatdeploy.trybytes32ToBytes(_sample2Bytes32)).to.equal(_sample2Bytes32);
	})

	it("should convert 'ace' to 0x616365", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleString,
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes(_sampleString)).to.equal(_sampleBytes2);
	})
	
	it("should convert 'test' to 0x74657374", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleBytes2,
			_sampleString,
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes('test')).to.equal('0x74657374');
	})

})
