// SPDX-License-Identifier: UNLICENSED  

pragma solidity ^0.8.7;



// SEE REMIX IDE


contract AssignRarity {

    
    
    uint[16] rarityDistribution = [1, 2, 4, 6, 7]; // production values: [9200, 15200, 18200, 19800, 20000]; 
    uint[5] rarities = [1, 2, 3, 4, 5];
    uint[5] public rarityCount = [0, 0, 0, 0, 0]; // edit visibility
    uint[5] rarityPercentage = [50, 60, 75, 85, 100];

    uint nonce;
    
    uint256 public maxSupply = 6; // 20,000; in real thing
    uint256 reservesLeft = 2; // 100; in real thing
    uint256 public cost = 0.025 ether;  // 0.025 wETH in actual // cost of minting // EDIT FOR POLYGON %%%%%%%
    uint256 mintsPerTx = 5; // 50 in actual %%%
    
    
    string public baseExtension = ".json";
    
    address team; // main net gnosis: 0x1873470f8B87B0F5B9484c06B65de7e945E58298
    

    
    
    
    
    // EVENTS //
    
    event TokenMinted(uint tokenId);
    
    event WinningTokenId(uint randomResult);
    
    
    // MAPPINGS //
    
    mapping(bytes32 => bool) outstandingVRFcalls;
    mapping(address => bool) whitelist;
    mapping(uint => uint) tokenRarityMap; // tokenId => rarity value (1-5)
    mapping(uint => uint) tokenRarityId; // tokenId to token number of rarity type at mint
    mapping(uint => string) public rarityURI;
    
    
    /**
     *   @notice Receives any tokens sent to the contract
     */
    receive() external payable {}
    
    
    
    // --- PUBLIC FUNCTIONS --- //
    
    
   
    


    // --- INTERNAL FUNCTIONS --- //


    /**
     * @dev Randomly generates token rarity based on weighted statistical distribution
     */
    function assignRarity(address _minter) public returns(uint) {

        uint rand = nonce; //(uint(keccak256(abi.encodePacked(_minter, block.timestamp, nonce))) % (maxSupply - totalSupply())) + 1; // 1-totalSupply
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

        return rarities[i];
    }
}