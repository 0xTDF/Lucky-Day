// SPDX-License-Identifier: UNLICENSED  

pragma solidity ^0.8.7;



/**
 * @title FiftyFifty
 * @dev Contract, inheriting from Ownable.sol and VRFConsumerBase.sol, for player vs player betting.
 */
contract disbTest {

    uint nonce;
    uint[3] public rarityDistribution = [1, 3, 5];
    uint[3] public rarityCount = [0, 0, 0];


    /**
     * @dev Randomly generates token rarity based on weighted statistical distribution
     */
    function determineRarity(uint _num) public {

        uint rand = _num; //((uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce))) % 3) + totalSupply) + 1; // 1-totalSupply
        nonce++;
        
        uint i = 0;
        while (i < rarityDistribution.length) { 
            if (rand <= rarityDistribution[i]) {
                break;
            }
            i++;
        }

        rarityCount[i]++;

        for (uint n = i; n < rarityDistribution.length; n++) {
            rarityDistribution[n]--;
        }
    
    }

}