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
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool)).to.equal("true");
	})
	
	it("should equal to `false' string from boolean", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryToConvertBoolToString = await expect(await hardhatdeploy.tryBoolToString(_sampleBool2)).to.equal("false");
	})
	
	it("should equal to `1` in string from uint", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToString = await expect(await hardhatdeploy.tryUintToString(_sampleUint)).to.equal("1");
	})
	
	it("should equal to `-1` in string from int", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToString = await expect(await hardhatdeploy.tryIntToString(_sampleInt)).to.equal("-1");
	})	
	
	it("should equal to `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4` in string from address", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToString = await expect(await hardhatdeploy.tryAddressToString(_sampleAddress)).to.equal(_sampleAddress);
	})	
	
	it("should equal to `ace` in string from byte32", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytes32ToString = await expect(await hardhatdeploy.tryBytes32ToString(_sampleByte32)).to.equal("ace");
	})
	
	it("should equal to true in boolean from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBool = await expect(await hardhatdeploy.tryBytesToBool(_sampleBytes)).to.equal(true);
	})

	it("should equal to 1 from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToUint = await expect(await hardhatdeploy.tryBytesToUint(_sampleBytes)).to.equal(100);
	})

/*	it("should equal to 100 in integers from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToInt = await expect(await hardhatdeploy.tryBytesToInt(_sampleBytes)).to.equal(100);
	})*/

	it("should equal to 100 in uint from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToAddress = await expect(await hardhatdeploy.tryBytesToAddress(_sampleBytes)).to.equal(_sampleAddressfrombyte);
	})

	it("should equal to _sample2Bytes32 from _sampleBytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToBytes32 = await expect(await hardhatdeploy.tryBytesToBytes32(_sampleBytes)).to.equal(_sample2Bytes32);
	})

	it("should equal to 'ace' in string from byte", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryBytesToString = await expect(await hardhatdeploy.tryBytesToString(_sampleBytes2)).to.equal("ace");
	})

/*	it("should convert bool to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryBoolToBytes = await hardhatdeploy.tryBoolToBytes(_sampleBool)
	})*/

	it("should convert uint to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryUintToBytes = await expect(await hardhatdeploy.tryUintToBytes(_sampleUint)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000001");
	})

	it("should convert int to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryIntToBytes = await expect(await hardhatdeploy.tryIntToBytes(100)).to.equal("0x0000000000000000000000000000000000000000000000000000000000000064");
	})

	it("should convert address to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryAddressToBytes = await expect(await hardhatdeploy.tryAddressToBytes(_sampleAddress)).to.equal(_sampleAddress);
	})

	it("should convert bytes32 to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const trybytes32ToBytes = await expect(await hardhatdeploy.trybytes32ToBytes(_sampleByte32)).to.equal(_sampleByte32);
	})

	it("should convert string to bytes", async function () {
		const { TypeConversions,
			hardhatdeploy,
			_sampleAddress,
			_sampleUint,
			_sampleInt,
			_sampleBool,
			_sampleBool2,
			_sampleBytes,
			_sampleBytes2,
			_sampleString,
			_sampleByte32,
			_sample2Bytes32,
			_sampleAddressfrombyte
		      } = await loadFixture(TypeConversionsFixture);
		const tryStringToBytes = await expect(await hardhatdeploy.tryStringToBytes(_sampleString)).to.equal(_sampleBytes2);
	})

})
