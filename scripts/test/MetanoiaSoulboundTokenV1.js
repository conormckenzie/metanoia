const testEnabled = true

if (!testEnabled) {
	return;
}

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("SoulBoundTokensV1 contract", function () {
	async function SoulBoundTokenV1Fixture() {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const SoulBoundTokenV1 = await ethers.getContractFactory("SoulBoundTokensV1");
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
	
	it("try to lockUri", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trylockUri = await expect(await hardhatdeploy.lockUri(1)).to.be.not.reverted
	})
	
	it("try to lock 0 and fail", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trylockUri = await expect(hardhatdeploy.lockUri(0)).to.be.reverted
	})
	
	it("try to setUri", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trysetUri = await expect(await hardhatdeploy.setUri(1, "sampleuri")).to.be.not.reverted
	})
	
	it("try to setUri with locked ID and fail", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trylockUri = await hardhatdeploy.lockUri(1)
		const trysetUri = await expect(hardhatdeploy.setUri(1, "sampleuri")).to.be.reverted
	})
	
	it("try to mint new SBT", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trymintNewSBT = await expect(await hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri")).to.be.not.reverted
	})
	
	it("try to mint an existing SBT with mintNewSBT and fail", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const mintNewSBT = await hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri");
		const trymintNewSBT = await expect(hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri")).to.be.reverted
	})
	
	it("try to mint a copy of an existing SBT", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trymintNewSBT = await hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri");
		const trymintExistingSBT = await expect(await hardhatdeploy.mintExistingSBT(addr1.address, 1, 1)).to.be.not.reverted
	})	
	
	it("try to mint a copy of non-existing SBT", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trymintNewSBT = await hardhatdeploy.mintNewSBT(owner.address, 1, 1, "sampleuri")
		const trymintExistingSBT = await expect(hardhatdeploy.mintExistingSBT(addr1.address, 2, 1)).to.be.reverted
	})
	
	it("try to register CouponEvent and should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const tryregisterCouponEvent = await expect(await hardhatdeploy.registerCouponEvent("test event")).to.be.not.reverted
	})
	
	it("try to grantCoupon and should not be reverted", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const tryregisterCouponEvent = await hardhatdeploy.registerCouponEvent("test event")
		const trygrantCoupon = await expect(await hardhatdeploy.grantCoupons(addr1.address, 1, 1)).to.be.not.reverted
	})
	
	it("try to redeemCoupon without granting and registering the coupon and fail", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const tryredeemCoupon = await expect(hardhatdeploy.redeemCoupon(1)).to.be.reverted
	})
	
	it("try to redeemCoupon after registering the coupon event and granting coupon.", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const tryregisterCouponEvent = await hardhatdeploy.registerCouponEvent("test event")
		const trygrantCoupon = await hardhatdeploy.grantCoupons(owner.address, 1, 1)
		const tryredeemCoupon = await expect(hardhatdeploy.redeemCoupon(1)).to.not.be.reverted
	})
	
	it("try to grant coupon with unregistered coupon and fail(to make sure grantCoupons is working properly)", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const trygrantCoupons = await expect(hardhatdeploy.grantCoupons(addr1.address, 1, 1)).to.be.reverted
	})
	
	it("try to register CouponEvent and verify it is registered by granting coupon(to verify registerCouponEvent is working properly)", async function () {
		const { SoulBoundTokenV1,
			hardhatdeploy,
			owner,
			addr1,
			addr2
		      } = await loadFixture(SoulBoundTokenV1Fixture);
		const tryregisterCouponEvent = await hardhatdeploy.registerCouponEvent("test event")
		const trygrantCoupons = await expect(await hardhatdeploy.grantCoupons(addr1.address, 1, 1)).to.be.not.reverted
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
