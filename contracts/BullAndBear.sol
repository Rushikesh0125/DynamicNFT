// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract BullAndBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatible {
    using Counters for Counters.Counter;

    VRFCoordinatorV2Interface public COORDINATOR;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint32 public callbackGasLimit = 500000; 
    uint64 public s_subscriptionId;
    bytes32 keyhash =  0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; 

    Counters.Counter private _tokenIdCounter;
    uint public interval;
    uint public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 currentPrice;

    enum MarketTrend{BULL, BEAR} 
    MarketTrend public currentMarketTrend = MarketTrend.BULL; 

    event TokenUpdated(
        string trend
    );

    constructor(uint256 updatedInterval, address _priceFeed, address _vrfCoordinator) ERC721("BullAndBear", "BAB") VRFConsumerBaseV2(_vrfCoordinator) {
        interval = updatedInterval;
        lastTimeStamp = block.timestamp;
        priceFeed = AggregatorV3Interface(_priceFeed);
        currentPrice = getLatestPrice(); 
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);  
    }

    string [] BullUris = [
        "https://ipfs.io/ipfs/QmS1v9jRYvgikKQD6RrssSKiBTBH3szDK6wzRWF4QBvunR?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRsTqwTXXkV8rFAT4XsNPDkdZs5WxUx9E5KwFaVfYWjMv?filename=party_bull.json",
        "https://ipfs.io/ipfs/Qmc3ueexsATjqwpSVJNxmdf2hStWuhSByHtHK5fyJ3R2xb?filename=simple_bull.json"
    ];

    string [] BearUris = [
        "https://ipfs.io/ipfs/QmQMqVUHjCAxeFNE9eUxf89H1b7LpdzhvQZ8TXnj4FPuX1?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmP2v34MVdoxLSFj1LbGW261fvLcoAsnJWHaBK238hWnHJ?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmZVfjuDiUfvxPM7qAvq8Umk3eHyVh7YTbFon973srwFMD?filename=simple_bear.json"
    ];

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        string memory defaultURI = BearUris[0];
        _setTokenURI(tokenId, defaultURI);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData */) {
         upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */ ) external{
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;         
            int latestPrice =  getLatestPrice();
        
            if (latestPrice == currentPrice) {
                return;
            }

            if (latestPrice < currentPrice) {
                // bear
                updateAllTokenUri("bear");

            } else {
                // bull
                updateAllTokenUri("bull");
            }

            // update currentPrice
            currentPrice = latestPrice;
        } else {

            return;
        }

       
    }


     function getLatestPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price; //  example price returned 3034715771688
    }

    function setInterval(uint256 newInterval) public onlyOwner{
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner{
        priceFeed = AggregatorV3Interface(newFeed);
    }

    function updateAllTokenUri(string memory trend) internal{
        if(compareStrings(trend, "bull")){
            for(uint i = 0; i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, BullUris[0]);
            }
        }else{
            for(uint i = 0; i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, BearUris[0]);
            }
        }

        emit TokenUpdated(trend);
    }

    function requestRandomnessForNFTUris() internal {
        require(s_subscriptionId != 0, "Subscription ID not set"); 

        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyhash,
            s_subscriptionId, // See https://vrf.chain.link/
            3, //minimum confirmations before response
            callbackGasLimit,
            1 
        );

    }

    function fulfillRandomWords( uint256, uint256[] memory randomWords) internal {
    s_randomWords = randomWords;

    string[] memory urisForTrend = currentMarketTrend == MarketTrend.BULL ? BullUris : BearUris;
    uint256 idx = randomWords[0] % urisForTrend.length; 

    for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
        _setTokenURI(i, urisForTrend[idx]);
    } 

    string memory trend = currentMarketTrend == MarketTrend.BULL ? "bullish" : "bearish";
    
    emit TokenUpdated(trend);
  }

    function compareStrings(string memory a, string memory b) internal returns(bool){
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}