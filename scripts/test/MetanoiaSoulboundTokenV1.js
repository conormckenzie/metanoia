const testEnabled = false

if (!testEnabled) {
	return;
}

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("SoulBoundTokenV1 contract", function () {
	async function SoulBoundTokenV1Fixture() {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const SoulBoundTokenV1 = await ethers.getContractFactory("SoulBoundTokenV1");
		const hardhatdeploy = await SoulBoundTokenV1.deploy();
		
		return { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
			};
	}
	
	it("contractURI should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trycontractURI = await expect(await hardhatdeploy.contractURI).to.be.not.reverted
	})
	
	it("setContractUri should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trycontractURI = await hardhatdeploy.contractURI
		const trysetContractUri = await expect(await hardhatdeploy.setContractUri(trycontractURI)).to.be.not.reverted
	})
	
	it("lockUri should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trylockUri = await expect(await hardhatdeploy.lockUri(1)).to.be.not.reverted
	})
	
	it("setUri should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trysetUri = await expect(await hardhatdeploy.setUri(1, "sampleuri")).to.be.not.reverted
	})
	
	it("mintNewSBT should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trymintNewSBT = await expect(await hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri")).to.be.not.reverted
	})
	
	it("mintExistingSBT should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trymintNewSBT = await hardhatdeploy.mintNewSBT(await owner.address, 5, 5, "sampleuri")
		const trymintExistingSBT = await expect(await hardhatdeploy.mintExistingSBT(owner.address, 5, 5)).to.be.not.reverted
	})	

	it("supportsInterface should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trysupportsInterface = await expect(await hardhatdeploy.supportsInterface).to.be.not.reverted
	})
	
})
