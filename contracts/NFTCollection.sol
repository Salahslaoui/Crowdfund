// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"
import "@openzeppelin/contracts/token/common/ERC2981.sol"

contract NFTCollection is ERC721, ERC721URIStorage, ERC2981 {

    uint public tokenCount;

    event Minted(uint indexed tokenId, address indexed creator, string tokenURI);

    constructor() ERC721("CrowdNFT", "CNFT") {}

    function mint(string calldata _tokenURI, uint96 royaltyFee) external {
        require(royaltyFee <= 1000, "Royalty too high, max 10%");
        tokenCount++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        _setDefaultRoyalty(msg.sender, royaltyFee);
        emit Minted(tokenCount, msg.sender, _tokenURI);
    }

    function tokenURI(uint tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
