// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract BullAndBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatible {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint public interval;
    uint public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 currentPrice;

    constructor(uint256 updatedInterval, address _priceFeed) ERC721("BullAndBear", "BAB") {
        interval = updatedInterval;
        lastTimeStamp = block.timestamp;
        priceFeed = AggregatorV3Interface(_priceFeed);
        currentPrice = getLatestPrice(); 
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
        string defaultURI = BearUris[0];
        _setTokenURI(tokenId, defaultURI);
    }

    function checkUpKeep(bytes calldata) external view override returns(bool upKeepNeeded, bytes memory){
        upKeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpKeep(bytes calldata) external override{
        if((block.timestamp - lastTimeStamp) > interval){
            lastTimeStamp = block.timestamp;
            int256 latestPrice = getLatestPrice();
            if(latestPrice == currentPrice){
                return;
            }
            if(latestPrice < currentPrice){
                updateAllTokenUri("bear");
            }else{
                updateAllTokenUri("bull");
            }

            currentPrice = latestPrice;

        }
    }

    function getLatestPrice() public view returns(int256){
        (int256 price) = priceFeed.latestRoundData();

        return price;
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