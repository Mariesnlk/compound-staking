require('@openzeppelin/test-helpers/configure')({
  provider: 'http://localhost:8545',
});
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from 'ethers'
const { BigNumber } = require("ethers");
const { constants } = require('@openzeppelin/test-helpers')

describe("Staking", function () {

  let cEther: Contract
  let eRC20Dev: Contract
  let aggregationV3: Contract
  let staking: Contract

  let owner: SignerWithAddress
  let stakeholder1: SignerWithAddress
  let stakeholder2: SignerWithAddress
  let stakeholder3: SignerWithAddress
  let stakeholder4: SignerWithAddress
  let otherAccounts: SignerWithAddress[]

  const PRECISION = "000000000000000000";
  let rewardsAmount: string = "1000".concat(PRECISION);
  let amount: string = "1000".concat(PRECISION);

  before(async () => {
    [owner, stakeholder1, stakeholder2, stakeholder3, stakeholder4, ...otherAccounts] = await ethers.getSigners();

    const CEther = await ethers.getContractFactory('CEther');
    const ERC20Dev = await ethers.getContractFactory('ERC20Dev');
    const AggregationV3 = await ethers.getContractFactory('AggregationV3');
    const Staking = await ethers.getContractFactory('Staking');
    cEther = await CEther.deploy();
    eRC20Dev = await ERC20Dev.deploy();
    aggregationV3 = await AggregationV3.deploy();

    const staking = await Staking.deploy(
      cEther.address,
      eRC20Dev.address,
      aggregationV3.address
    );

    const totalSupply = await eRC20Dev.totalSupply();
    await eRC20Dev.approve(staking.address, totalSupply);

  });

  describe("Deployment", function () {
    it("Should get all addresses", async function () {
      expect(staking.CETH_TOKEN()).to.be.equal(cEther.address);
      expect(staking.REWARD_TOKEN()).to.be.equal(eRC20Dev.address);
      expect(staking.priceFeed()).to.be.equal(aggregationV3.address);
    });

    it("Should fail if cEther address is zero", async function () {
      const Staking = await ethers.getContractFactory('CoreStaking');
      await expect(Staking.deploy(constants.ZERO_ADDRESS, eRC20Dev.address, aggregationV3.address))
        .to.be.revertedWith("ZERO_ADDRESS");
    });

    it("Should fail if eRC20Dev address is zero", async function () {
      const Staking = await ethers.getContractFactory('CoreStaking');
      await expect(Staking.deploy( cEther.address, constants.ZERO_ADDRESS, aggregationV3.address))
        .to.be.revertedWith("ZERO_ADDRESS");
    });

    it("Should fail if aggregationV3 address is zero", async function () {
      const Staking = await ethers.getContractFactory('CoreStaking');
      await expect(Staking.deploy( cEther.address, eRC20Dev.address, constants.ZERO_ADDRESS))
        .to.be.revertedWith("ZERO_ADDRESS");
    });

  });
});
