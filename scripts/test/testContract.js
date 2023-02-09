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
		const MixieBase = await ethers.getContractFactory("conortest");
		const hardhatdeploy = await MixieBase.deploy();
		
		return { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		};
	}

    it("fails successfully", async function() {
        const { MixieBase,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(MixieBaseFixture);
		const trytestMint = await expect(hardhatdeploy.testFail()).to.be.reverted;
    });
})