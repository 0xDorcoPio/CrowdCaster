const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");  
const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

describe('CrowdCaster', () => {

    async function createCampaignFixture(){
        const [owner, otherAccount] = await ethers.getSigners();
        const amount = 1e9; // 1 GWEI
        const deadline = (await time.latest()) + 60; // now + 1 minute

        const CrowdCaster = await ethers.getContractFactory('CrowdCaster');
        crowdCaster = await CrowdCaster.deploy(amount, deadline) // 1 ether
        
        return { crowdCaster, owner, amount, deadline };
    }

    describe("Deployment", function () {
        it('Should set the right owner', async () => {
            const { crowdCaster, owner } = await loadFixture(createCampaignFixture());
            
            console.log(owner)
            expect(await crowdCaster.owner()).to.equal(owner.address)
        })
    })
})