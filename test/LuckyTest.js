
// truffle test test/LuckyTest.js --compile-none

const wETHmock = artifacts.require("wETHmock");
const LuckyDay = artifacts.require("LuckyDay");

var chai = require("./setupchai.js");
const BN = web3.utils.BN;
const expect = chai.expect;

const truffleAssert = require('truffle-assertions');
const { assert } = require('chai');


contract("Lucky Day", async accounts => {

    let wETH;
    let ld;
    
    beforeEach(async () => {
        wETH = await wETHmock.new();
        ld = await LuckyDay.new(wETH.address, accounts[9]);        
    });

    
    it('has default values', async () => {

        expect(await ld.maxSupply()).to.be.a.bignumber.equal(new BN(6)) // 20,000 in actual
        expect(await ld.cost()).to.be.a.bignumber.equal(new BN(web3.utils.toWei('0.025', 'ether')))
    
        expect(await ld.preSaleStatus()).to.equal(false)
        expect(await ld.publicSaleStatus()).to.equal(false)
    
    
        expect(await ld.name()).to.equal('Lucky Day')
        expect(await ld.symbol()).to.equal('LUCKY')
    
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))
        expect(await ld.numberOfDraws()).to.be.a.bignumber.equal(new BN(0))
    
    })

    
    it('can change sale status', async () => {

        // initial values
        expect(await ld.publicSaleStatus()).to.equal(false)
        expect(await ld.preSaleStatus()).to.equal(false)

        // only pre sale live
        await ld.setPreSaleStatus(true)
        expect(await ld.preSaleStatus()).to.equal(true)
        expect(await ld.publicSaleStatus()).to.equal(false)

        // only public live
        await ld.setPublicSaleStatus(true)
        expect(await ld.publicSaleStatus()).to.equal(true)
        expect(await ld.preSaleStatus()).to.equal(false)

        // everyhting not live
        await ld.setPublicSaleStatus(false)
        expect(await ld.publicSaleStatus()).to.equal(false)
        expect(await ld.preSaleStatus()).to.equal(false)
    })

    
    it('owner can set mint cost', async () => {

        expect(await ld.cost()).to.be.a.bignumber.equal(new BN(web3.utils.toWei('0.025', 'ether')))
        await ld.setCost(web3.utils.toWei('1', 'ether'))
        expect(await ld.cost()).to.be.a.bignumber.equal(new BN(web3.utils.toWei('1', 'ether')))

        // sets cost back to origanal
        await ld.setCost(web3.utils.toWei('0.05', 'ether'))
        expect(await ld.cost()).to.be.a.bignumber.equal(new BN(web3.utils.toWei('0.05', 'ether')))
    
    })

    it('can airdrop tokens', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))

        await ld.airDrop([accounts[4], accounts[5]])
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(2))
        expect(await ld.balanceOf(accounts[4])).to.be.a.bignumber.equal(new BN(1))
        expect(await ld.balanceOf(accounts[5])).to.be.a.bignumber.equal(new BN(1))
    
    })

    
    it('can mint from public sale', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0));

        // tries to mint before public sale live
        await truffleAssert.reverts(
            ld.mint(1),
            "It's not time yet"
        );

        await ld.setPublicSaleStatus(true);
        expect(await ld.publicSaleStatus()).to.equal(true);

        // tries to mint before approving
        await truffleAssert.reverts(
            ld.mint(1),
            "Must directly approve wETH first"
        );
        
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0));
        await wETH.approve(ld.address, new BN(web3.utils.toWei('0.125', 'ether')));
        await ld.mint(3);
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(3));

        // tries to mint tokens that would exceed MAX_SUPPLY
        await truffleAssert.reverts(
            ld.mint(2),
            "Minting that many would exceed max supply"
        );

        await ld.mint(1);
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(4));
        
        expect(await wETH.balanceOf(ld.address)).to.be.a.bignumber.equal(new BN(web3.utils.toWei('0.085', 'ether')));
        expect(await wETH.balanceOf(accounts[9])).to.be.a.bignumber.equal(new BN(web3.utils.toWei('0.015', 'ether')));
    
    })

    
    /*
    it('returns token URI but only for minted tokens', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))

        await ld.setPublicSaleStatus(true)
        expect(await ld.publicSaleStatus()).to.equal(true)

        // tries to read tokenURI for token yet to be minted
        await truffleAssert.reverts(
            ld.tokenURI(1),
            "ERC721Metadata: URI query for nonexistent token"
        );
        
        await wETH.approve(ld.address, new BN(web3.utils.toWei('0.25', 'ether')));
        await ld.mint(1)
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(1))
        expect(await ld.tokenURI(1)).to.equal('01.json')

        await ld.mint(1)
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(2))
        expect(await ld.tokenURI(2)).to.equal('02.json')
    
    })
    */
    
    
})