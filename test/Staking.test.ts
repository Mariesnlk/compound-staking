import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, constants } from 'ethers'
import { time, takeSnapshot, SnapshotRestorer } from '@nomicfoundation/hardhat-network-helpers';

describe("Staking", function () {
  const ONE_WEEK: number = 7 * 24 * 60 * 60;

  const ether = ethers.utils.parseEther;

  let cEther: Contract
  let eRC20Dev: Contract
  let aggregationV3: Contract
  let staking: Contract

  let owner: SignerWithAddress
  let stakeholder1: SignerWithAddress
  let stakeholder2: SignerWithAddress
  let otherAccounts: SignerWithAddress[]

  let snapshot: SnapshotRestorer

  let rewardsAmount: string = "10000";
  let stakedAmount: string = "5";

  before(async () => {
    [owner, stakeholder1, stakeholder2, ...otherAccounts] = await ethers.getSigners();

    const CEther = await ethers.getContractFactory('CEther');
    const ERC20Dev = await ethers.getContractFactory('ERC20Dev');
    const AggregationV3 = await ethers.getContractFactory('AggregationV3');
    const Staking = await ethers.getContractFactory('Staking');
    cEther = await CEther.deploy();
    eRC20Dev = await ERC20Dev.deploy();
    aggregationV3 = await AggregationV3.deploy();

    staking = await Staking.deploy(
      cEther.address,
      eRC20Dev.address,
      aggregationV3.address
    );

    const totalSupply = await eRC20Dev.totalSupply();
    await eRC20Dev.approve(staking.address, totalSupply);

    snapshot = await takeSnapshot();

  });

  afterEach(async () => {
    await snapshot.restore();
  });

  describe("Deployment", function () {
    it("Should get all addresses", async function () {
      expect(await staking.CETH_TOKEN()).to.be.equal(cEther.address);
      expect(await staking.REWARD_TOKEN()).to.be.equal(eRC20Dev.address);
      expect(await staking.priceFeed()).to.be.equal(aggregationV3.address);
    });

    it("Should fail if cEther address is zero", async function () {
      const Staking = await ethers.getContractFactory('Staking');
      await expect(Staking.deploy(constants.AddressZero, eRC20Dev.address, aggregationV3.address))
        .to.be.revertedWithCustomError(staking, "ZeroAddress");
    });

    it("Should fail if eRC20Dev address is zero", async function () {
      const Staking = await ethers.getContractFactory('Staking');
      await expect(Staking.deploy(cEther.address, constants.AddressZero, aggregationV3.address))
        .to.be.revertedWithCustomError(staking, "ZeroAddress");
    });

    it("Should fail if aggregationV3 address is zero", async function () {
      const Staking = await ethers.getContractFactory('Staking');
      await expect(Staking.deploy(cEther.address, eRC20Dev.address, constants.AddressZero))
        .to.be.revertedWithCustomError(staking, "ZeroAddress");
    });
  });

  describe("stake", function () {
    it("Should fail if staked amount is less than 5 ETH", async function () {
      await expect(staking.connect(stakeholder1).stake({ value: ether("1") }))
        .to.be.revertedWithCustomError(staking, "LessThanValidAmount");
    });

    it("Should staked for the first time", async function () {
      let stakeholder = await staking.stakeholders(stakeholder1.address);
      expect(stakeholder.stakedAmount).to.be.equal(0);

      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });

      stakeholder = await staking.stakeholders(stakeholder1.address);
      expect(stakeholder.stakedAmount).to.be.equal(ether(stakedAmount));
    });

    it("Should staked for the second time with calculation previous reward", async function () {
      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });

      await time.increase(10 * ONE_WEEK);

      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });

      //check calculation
    });

    it("Should staked with two users", async function () {
      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });

      await staking.connect(stakeholder2).stake({ value: ether(stakedAmount) });

      const user1 = await staking.stakeholders(stakeholder1.address);
      expect(user1.stakedAmount).to.be.equal(ether(stakedAmount));
      const user2 = await staking.stakeholders(stakeholder2.address);
      expect(user2.stakedAmount).to.be.equal(ether(stakedAmount));

      expect(await staking.totalStakedAmount()).to.be.equal(ether("10"));
    });

    it("Should emit event correctly", async function () {
      await expect(staking.connect(stakeholder1).stake({ value: ether(stakedAmount) }))
        .to.emit(staking, "Staked")
        .withArgs(stakeholder1.address, ether(stakedAmount));
    });
  });

  describe.only("withdraw", function () {
    it("Should fail withdraw amount in ether is invalid (amount=0)", async function () {
      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });
      await time.increase(10 * ONE_WEEK);

      await expect(staking.connect(stakeholder1).withdraw(0))
        .to.be.revertedWithCustomError(staking, "InvalidWithdrawAmount");
    });

    it("Should fail if user has not staked before", async function () {
      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });
      await time.increase(10 * ONE_WEEK);

      await expect(staking.connect(stakeholder1).withdraw(ether("10")))
        .to.be.revertedWithCustomError(staking, "InvalidWithdrawAmount");
    });

    it.only("Should withdraw some ether", async function () {
      await staking.connect(stakeholder1).stake({ value: ether(stakedAmount) });
      await time.increase(10 * ONE_WEEK);

      await staking.connect(stakeholder1).withdraw(ether("2"));
    });
  });
});
