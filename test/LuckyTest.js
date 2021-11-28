
// truffle test test/LuckyTest.js --compile-none


const LuckyDay = artifacts.require("LuckyDay");

var chai = require("./setupchai.js");
const BN = web3.utils.BN;
const expect = chai.expect;

const truffleAssert = require('truffle-assertions');
const { assert } = require('chai');


contract("Lucky Day", async accounts => {

    let ld;
    
    beforeEach(async () => {
        ld = await LuckyDay.deployed();
    });


    

    
})