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
 * @title FiftyFifty
 * @dev Contract, inheriting from Ownable.sol and VRFConsumerBase.sol, for player vs player betting.
 */
contract LuckyDay is Ownable, ERC721Enumerable, VRFConsumerBase {  
    
    
    uint256 public MAX_SUPPLY = 20000; // 20,000 in real thing
    uint256 public cost = 0.05 ether;  // cost of minting // EDIT FOR POLYGON %%%%%%%
    
    bool public generalSaleStatus = false;
    
    string public baseExtension = ".json";
    uint public firstRaffleTimestamp = 1637771383; // EDIT BEFORE PRODUCTION DEPLOYMENT %%%%%%%%%
    uint public numberOfDraws;
    
    string public baseURI = "ipfs://QmfJctvqKgik28etZYtZUAbiQmZ7amj7rpsuEZjxFVmgEL/"; // %%%%%%%%%
    
    address payable A = payable(0x8641748C05C3AbB0a29A07c8A425c160dCB5Ade1); // %%%%%%%%%%
    address payable B = payable(0xB70D6076ee01Be23C93aadF00754864c82cc44A8); // %%%%%%%%%%
    address payable C = payable(0xfAEB58f87e74DC1A7220efdeFb5633De543C0cB8); // %%%%%%%%%%
    
    
    // VRF VARIABLES //
    
    bytes32 public keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4; // for Polygon Mumbai Test Network ONLY %%%%%
    uint256 public fee = 0.0001 * 10 ** 18; // 0.0001 LINK VRF fee for Polygon ONLY %%%%
    uint256 public randomResult;

   
    
    // CONSTRUCTOR //
    
    /**
     * @dev  Chainlink VRF set up for Polygon Mumbai Test Network -- For main net deployment see [https://docs.chain.link/docs/vrf-contracts/]
     * 
     */
    constructor() 
        Ownable() 
        ERC721("Lucky Day", "LUCKY") 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,  // VRF Coordinator for Polygon Mumbai Test Network ONLY %%%%
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token address on Polygon Mumbai Test Network ONLY %%%%
        ) {}
    
    
    // EVENTS //
    
    event TokenMinted(uint tokenId);
    
    event WinningTokenId(uint randomResult);
    
    
    // MAPPINGS //
    
    mapping(bytes32 => bool) outstandingVRFcalls;
    
    
    /**
     *   @notice Will receive any tokens sent to the contract
     */
    receive() external payable {}
    
    
    
    // NFT FUNCTIONS //
    
    
    function mint(uint256 _num) public payable { 
        
        require(generalSaleStatus, "It's not time yet"); // checks general sale is live
        require(msg.value == _num * cost, "Incorrect funds supplied"); // mint cost
        require(_num > 0 && _num <= 50, "Maximum of 50 mints allowed"); // mint limit per tx
        require(totalSupply() + _num <= MAX_SUPPLY, "Minting that many would exceed max supply");
        
        for (uint256 i = 0; i < _num; i++) {
            uint tokenId = totalSupply() + 1;
            _mint(msg.sender, tokenId);
            emit TokenMinted(tokenId);
            
        }

        uint commission = msg.value / 10;
        uint cut = commission / 3;

        A.transfer(cut);
        B.transfer(cut);
        C.transfer(cut);
        
    }
    
    
    
    ///// LINK VRF FUNCTIONS ////
    
    
    function startRaffleDraw() public {
        require(LINK.balanceOf(address(this)) >= fee, "Insufficient LINK to cover VRF fee");
        //require(block.timestamp >= (firstRaffleTimestamp + (numberOfDraws*7*24*60*60)), "It's not time yet!"); 
        numberOfDraws++;
        outstandingVRFcalls[getRandomNumber()] = true;
    }
    
    
    function getRandomNumber() internal returns(bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }
    

    //
    address public winner; // TESTING ONLY
    uint public winnings; // TESTING ONLY
    //

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        require(outstandingVRFcalls[requestId], "No outstanding VRF call for this requestId");
        outstandingVRFcalls[requestId] = false;
        
        randomResult = (randomness % totalSupply()) + 1; // returns value between 1 and the totalSupply
        emit WinningTokenId(randomResult);

        winner = ownerOf(randomResult); // gets address of winning token owner
        winnings = address(this).balance / 10; 
        
        payable(winner).transfer(winnings);
    }
    
    
    
    
    
    
    ///// VIEW FUNCTIONS ////
    
    
    /**
     * @dev Returns tokenURI which is comprised of the baseURI concatenated with the tokenId
     */
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
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
     * @dev Withdraw amount '_amount' of LINK from smart contract to address '_to'. Unit: wei
     * 
     * Note: Only contract owner can call.
     */
    function withdrawLink(uint _amount, address payable _to) public onlyOwner {
        
        require(_amount <= LINK.balanceOf(address(this)), "Withdrawel amount greater than balance.");
        
        LINK.transfer(_to, _amount);  // withdraws amount '_amount' to specified address '_to'
        
    }
    
    
    /**
     * @dev Set the status of the general sale
     * @param _status boolean where true = live 
     */
    function setGeneralSaleStatus(bool _status) external onlyOwner {
        generalSaleStatus = _status;
    }
    
    
    /**
     * @dev Set the cost of minting a token
     * @param _newCost in Wei. Where 1 Wei = 10^-18 ether
     */
    function setCost(uint _newCost) external onlyOwner {
        cost = _newCost;
    }
    
    
    /**
     * @dev Set the baseURI string
     */
    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }
    
    
    /**
     * @dev Set the base extension. '.json' by default.
     */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    
    /**
     * @dev Airdrop 1 token to each address in array '_to'
     * @param _to - array of address' that tokens will be sent to
     */
    function airDrop(address[] calldata _to) external onlyOwner {
        for (uint i=0; i<_to.length; i++) {
            uint tokenId = totalSupply() + 1;
            require(tokenId <= MAX_SUPPLY, "All tokens have been minted");
            _mint(_to[i], tokenId);
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

