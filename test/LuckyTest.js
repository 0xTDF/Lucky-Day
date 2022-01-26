
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
        ld = await LuckyDay.new(wETH.address);
        
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

    /*
    it('can mint from public sale but no more than MAX_SUPPLY and no more than 50 per tx', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))

        // tries to mint before public sale live
        await truffleAssert.reverts(
            ld.mint(1, { value: 0.05e18, from: accounts[9] }),
            "It's not time yet"
        );

        await ld.setpublicSaleStatus(true) 
        expect(await ld.publicSaleStatus()).to.equal(true)

        // tries to mint more than 5 tokens
        await truffleAssert.reverts(
            ld.mint(6, { value: 0.3e18, from: accounts[9] }),
            "Maximum of 50 mints allowed"
        );

        await ld.mint(4, { value: 0.2e18, from: accounts[9] })

        // tries to mint tokens that would exceed MAX_SUPPLY
        await truffleAssert.reverts(
            ld.mint(3, { value: 0.15e18, from: accounts[9] }),
            "Minting that many would exceed max supply"
        );

        await ld.mint(2, { value: 0.1e18, from: accounts[9] })
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(6))
    
    
    })

    
    
    it('returns token URI but only for minted tokens', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))

        await ld.setpublicSaleStatus(true)
        expect(await ld.publicSaleStatus()).to.equal(true)

        // tries to read tokenURI for token yet to be minted
        await truffleAssert.reverts(
            ld.tokenURI(1),
            "ERC721Metadata: URI query for nonexistent token"
        );
        
        await ld.mint(1, { value: 0.05e18, from: accounts[9] })
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(1))
        expect(await ld.tokenURI(1)).to.equal('testURI1.json')

        await ld.mint(1, { value: 0.05e18, from: accounts[9] })
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(2))
        expect(await ld.tokenURI(2)).to.equal('testURI2.json')
    
    })


    it('can set base URI', async () => {

        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(0))
        await ld.setpublicSaleStatus(true)
        expect(await ld.publicSaleStatus()).to.equal(true)

        await ld.mint(1, { value: 0.025e18, from: accounts[9] })
        expect(await ld.totalSupply()).to.be.a.bignumber.equal(new BN(1))
        expect(await ld.tokenURI(1)).to.equal('testURI1.json')

        await ld.setBaseUri('editedBaseURI')
        expect(await ld.tokenURI(1)).to.equal('editedBaseURI1.json')

    })
    */
    

    
})