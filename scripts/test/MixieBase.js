const testEnabled = true

if (!testEnabled) {
	return;
}

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("MixieBase contract", function () {
	async function MixieBaseFixture() {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const MixieBase = await ethers.getContractFactory("OnChainTestNftV1_1");
		const hardhatdeploy = await MixieBase.deploy();
		
		return { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
			};
	}
	
	it("testMint should not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trytestMint = await expect(await hardhatdeploy.testMint(addr1.address, 1)).to.be.not.reverted
	})
	
	it("uriGasTest should not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const tryuriGasTest = await expect(await hardhatdeploy.uriGasTest(1)).to.be.not.reverted
	})
	
	it("changeForceChecked should not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trychangeForceChecked = await expect(await hardhatdeploy.changeForceChecked(true)).to.be.not.reverted
	})
	
	it("authorizeAddressForWritingAttributes should not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const tryauthorizeAddressForWritingAttributes = await expect(await hardhatdeploy.authorizeAddressForWritingAttributes(addr1.address, true)).to.be.not.reverted
	})
	
	it("registerAttribute should not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const tryaregisterAttribute = await expect(await hardhatdeploy.registerAttribute("TrueorFalse", "bool", "false")).to.be.not.reverted
	})

	it("isRegistered should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const tryisRegistered = await expect(await hardhatdeploy.isRegistered(1)).to.be.reverted
	})
	
	it("getAttributeIdFromName not be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trygetAttributeIdFromName = await expect(await hardhatdeploy.getAttributeIdFromName("TrueorFalse")).to.reverted
	})
	
	it("getAttributeById should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trygetAttributeById = await expect(await hardhatdeploy.getAttributeById(1,1,false,false)).to.be.reverted
	})
	
	it("getAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trygetAttribute = await expect(await hardhatdeploy.getAttribute(1,"TrueorFalse",false,false)).to.be.reverted
	})
	
	it("_setAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const try_setAttribute = await expect(await hardhatdeploy._setAttribute(1,1,false,"false")).to.be.reverted
	})
	
	it("setAttributeById should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetAttributeById = await expect(await hardhatdeploy.setAttributeById(1,1,false,"false")).to.be.reverted
	})
	
	it("setAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetAttribute = await expect(await hardhatdeploy.setAttribute(1,"TrueorFalse",false,"false")).to.be.reverted
	})
	
	it("setBoolAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetBoolAttribute = await expect(await hardhatdeploy.setBoolAttribute(1,"TrueorFalse",false,false)).to.be.reverted
	})
	
	it("setUintAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetUintAttribute = await expect(await hardhatdeploy.setUintAttribute(1,"uint",false,1)).to.be.reverted
	})
	
	it("setIntAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetIntAttribute = await expect(await hardhatdeploy.setIntAttribute(1,"int",false,1)).to.be.reverted
	})

	it("setAddressAttribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetAddressAttribute = await expect(await hardhatdeploy.setAddressAttribute(1,"addr",false,"fx21sdfdfdSd")).to.be.reverted
	})

	it("setBytes32Attribute should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetBytes32Attribute = await expect(await hardhatdeploy.setBytes32Attribute(1,"byte32",false,"0x12")).to.be.reverted
	})

	it("setUriVisibility should be reverted", async function () {
		const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trysetUriVisibility = await expect(await hardhatdeploy.setUriVisibility("", true)).to.be.reverted
	})

})
