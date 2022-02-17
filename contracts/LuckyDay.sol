// SPDX-License-Identifier: UNLICENSED  

pragma solidity ^0.8.7;



/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
 * By default, the owner account will be the one that deploys the contract. This can later be changed with transferOwnership.
 */
import "@openzeppelin/contracts/access/Ownable.sol";  

/**
 * @dev ERC721 token standard
 */
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev Contract module which provides verifiable randomness 
 */
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * @dev ERC20 token interface
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




/**
 * @title LuckyDay
 * @dev 20,000 NFT 'charms' acting as tickets to a perpetual lottery funded by token sales.
 */
contract LuckyDay is Ownable, ERC721Enumerable, VRFConsumerBase {

    IERC20 internal wETH; // = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    
    uint[16] rarityDistribution = [1, 2, 4, 6, 7]; // production values: [9200, 15200, 18200, 19800, 20000]; 
    uint[5] rarities = [1, 2, 3, 4, 5];
    uint[5] public rarityCount = [0, 0, 0, 0, 0]; // edit visibility
    uint[5] rarityPercentage = [50, 60, 75, 85, 100];

    uint nonce;
    
    uint256 public maxSupply = 6; // 20,000; in real thing
    uint256 reservesLeft = 2; // 100; in real thing
    uint256 public cost = 0.025 ether;  // 0.025 wETH in actual // cost of minting // EDIT FOR POLYGON %%%%%%%
    uint256 mintsPerTx = 5; // 50 in actual %%%
    
    bool public preSaleStatus;
    bool public publicSaleStatus;
    
    uint public firstRaffleTimestamp = 1637771383; // EDIT BEFORE PRODUCTION DEPLOYMENT %%%%%%%%%
    uint public numberOfDraws;
    uint public prizePoolPercentage = 50; // Max amount of prize pool that can be won (i.e. raffle winner holds rarest token type)
    
    string public baseExtension = ".json";
    
    address team; // main net gnosis: 0x1873470f8B87B0F5B9484c06B65de7e945E58298
    

    // --- VRF VARIABLES --- //
    
    bytes32 public keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4; // for Polygon Mumbai Test Network ONLY %%%%%
    uint256 public fee = 0.0001 * 10 ** 18; // 0.0001 LINK VRF fee for Polygon ONLY 
    uint256 public randomResult;

    address vrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255; // MUMBAI TESTNET ONLY %%%%
    address linkTokenAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // MUMBAI TESTNET ONLY %%%%
    

    // --- CONSTRUCTOR --- //
    
    /**
     * @dev  Chainlink VRF set up for Polygon Mumbai Test Network -- For main net deployment see [https://docs.chain.link/docs/vrf-contracts/]
     * 
     */
    constructor(address _wETHaddress, address _teamAddress) 
        Ownable() 
        ERC721("Lucky Day", "LUCKY") 
        VRFConsumerBase(
            vrfCoordinator,  // VRF Coordinator for Polygon Mumbai Test Network ONLY %%%%
            linkTokenAddress  // LINK Token address on Polygon Mumbai Test Network ONLY %%%%
        ) {
            wETH = IERC20(_wETHaddress);

            rarityURI[1] = "one"; // EDIT
            team = _teamAddress;
        }
    
    
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
    
    
    function mint(uint256 _num) public payable {
        
        if (preSaleStatus) {
            require(whitelist[msg.sender], "Not on whitelist"); 
        } else {
            require(publicSaleStatus, "It's not time yet"); // checks public sale is live
        }
        
        require(_num * cost <= wETH.allowance(msg.sender, address(this)), "Must directly approve wETH first");
        require(totalSupply() + _num + reservesLeft <= maxSupply, "Minting that many would exceed max supply");

        wETH.transferFrom(msg.sender, address(this), _num*cost);
        
        for (uint256 i = 0; i < _num; i++) {
            uint tokenId = totalSupply() + 1;
            _mint(msg.sender, tokenId);
            
            uint tokenRarity = assignRarity(msg.sender);
            tokenRarityMap[tokenId] = tokenRarity;
            tokenRarityId[tokenId] = rarityCount[tokenRarity];
            
            emit TokenMinted(tokenId);
        }

        uint commission = (_num*cost*15) / 100;
        wETH.transfer(team, commission);
        
    }
    


    // --- INTERNAL FUNCTIONS --- //


    /**
     * @dev Randomly generates token rarity based on weighted statistical distribution
     */
    function assignRarity(address _minter) public returns(uint) { // EDIT: change visibility

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


    
    
    // --- LINK VRF FUNCTIONS --- //
    
    
    function startRaffleDraw() public {
        require(block.timestamp >= (firstRaffleTimestamp + (numberOfDraws*7*24*60*60)), "It's not time yet!"); 
        require(LINK.balanceOf(address(this)) >= fee, "Insufficient LINK to cover VRF fee");
        numberOfDraws++;
        outstandingVRFcalls[requestRandomness(keyHash, fee)] = true;
    }
    
    

    // -----------------------------------
    address public winner; // TESTING ONLY
    uint public winnings; // TESTING ONLY
    // -----------------------------------

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        require(msg.sender == vrfCoordinator); 
        require(outstandingVRFcalls[requestId], "No outstanding VRF call for this requestId");
        outstandingVRFcalls[requestId] = false;
        
        randomResult = (randomness % totalSupply()) + 1; // returns value between 1 and the totalSupply
        emit WinningTokenId(randomResult);

        winner = ownerOf(randomResult); // gets address of winning token owner
        uint onePercent = address(this).balance / 100;

        wETH.transfer(team, onePercent); // CHANGE to be multisig address
        
        payable(winner).transfer(prizePoolPercentage*onePercent*(rarityPercentage[tokenRarityMap[randomResult] - 1])/100);
    }

    

    
    
    
    
    
    
    ///// VIEW FUNCTIONS ////
    
    
    /**
     * @dev Returns tokenURI which is comprised of the baseURI concatenated with the tokenId
     */
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(rarityURI[tokenRarityId[_tokenId]], Strings.toString(tokenRarityId[_tokenId]), baseExtension));

        // return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
    }
    
    
    /**
     * @dev View contract LINK balance.
     * 
     */
    function viewLinkBalance() public view returns(uint) {
        return LINK.balanceOf(address(this)); 
    }

    
    
    
  
    //  ONLY OWNER //


    
    /**
     * @dev Withdraw amount '_amount' of any ERC20 token from the smart contract transfering it to address '_recipient'. Unit: wei
     * 
     * Note: Only contract owner can call. wETH withdrawals are prohibited.
     */
    function withdrawTokens(IERC20 _tokenAddress, uint _amount, address payable _recipient) external onlyOwner {
        require(_tokenAddress != IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619), "wETH withdrawal is prohibited");
        IERC20(_tokenAddress).transfer(_recipient, _amount);
    }

    /**
     * @dev Set the status of the pre sale
     * @param _status boolean where true = live 
     */
    function setPreSaleStatus(bool _status) external onlyOwner {
        publicSaleStatus = false;
        preSaleStatus = _status;
    }
    
    /**
     * @dev Set the status of the public sale
     * @param _status boolean where true = live 
     */
    function setPublicSaleStatus(bool _status) external onlyOwner {
        preSaleStatus = false;
        publicSaleStatus = _status;
    }
    
    
    /**
     * @dev Set the cost of minting a token
     * @param _newCost in Wei. Where 1 Wei = 10^-18 ether
     */
    function setCost(uint _newCost) external onlyOwner {
        cost = _newCost;
    }
    

    /**
     * @dev Set the maximum prize pool % that can be won by a raffle winner if winning token is rarest type
     * @param _newPercentage - % of wETH in prize pool
     */
    function setPrizePoolPercentage(uint _newPercentage) external onlyOwner {
        prizePoolPercentage = _newPercentage;
    }
    
    /**
     * @dev Set the baseURI string
     */
    function setRarityUri(uint _rarity, string memory _newURI) external onlyOwner {
        rarityURI[_rarity] = _newURI;
    }
    
    
    /**
     * @dev Set the base extension. '.json' by default.
     */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }


    /**
     * @dev Add addresses to white list, giving access to pre sale minting
     * @param _addresses - array of address' to add to white list mapping
     */
    function whitelistAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint i=0; i<_addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }
    
    
    /**
     * @dev Airdrop 1 token to each address in array '_to'
     * @param _to - array of address' that tokens will be sent to
     */
    function airDrop(address[] calldata _to) external onlyOwner {

        require(_to.length <= reservesLeft, "Minting that many would exceed reserves left.");
        require(totalSupply() + _to.length <= maxSupply, "All tokens have been minted");

        for (uint i=0; i<_to.length; i++) {
            uint tokenId = totalSupply() + 1;
            _mint(_to[i], tokenId);
            /*
            uint tokenRarity = assignRarity(_to[i]);
            tokenRarityMap[tokenId] = tokenRarity;
            tokenRarityId[tokenId] = rarityCount[tokenRarity];
            */
            reservesLeft--;
            emit TokenMinted(tokenId);
        }
        
    }

    



    // TEST PURPOSES

    function viewBalance() public view returns(uint) {
        return address(this).balance;
    }

    function testMint(uint _num, address _to) public {
        for (uint256 i = 0; i < _num; i++) {
            uint tokenId = totalSupply() + 1;
            _mint(_to, tokenId);
            emit TokenMinted(tokenId);
        }
    }
    
}

