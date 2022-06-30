const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking contract test", function() {
   let Staking;
   let TTT;
   let USDT;

   let staking;
   let ttt;
   let usdt;

   let owner;
   let address1;
   let address2;

   beforeEach(async function () {
       Staking = await ethers.getContractFactory("Staking");
       TTT = await ethers.getContractFactory("TTT");
       USDT = await ethers.getContractFactory("MockERC20");
       [owner, address1, address2] = await ethers.getSigners();

       ttt = await TTT.deploy();
       usdt = await USDT.deploy();
       staking = await Staking.deploy(usdt.address, ttt.address);

       await usdt.mint(owner.address, 10);
       await usdt.approve(staking.address, 2);
   });

   it("Should create stake on sender's account", async function () {
       //await usdt.mint(owner.address, 10);
       //await usdt.approve(staking.address, 1);
       await staking.createStake(1, {from: owner.address});
       const stake = await staking.stakeOf(owner.address);
       expect(await usdt.balanceOf(owner.address)).to.equal(9);
       expect(stake).to.equal(1);
   });

   it("Should remove stake from sender's account", async function () {
       //await usdt.approve(staking.address, 1);
       await staking.createStake(2, {from: owner.address});
       await staking.removeStake(2);
       const stake = await staking.stakeOf(owner.address);
       expect(stake).to.equal(0);
   });


});