// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Marketplace {
    
    uint public listCount;
    uint public platformFee;
    address public owner;

    struct Listing {
        address seller;
        address nftContract;
        uint tokenId;
        uint price;
        bool active;
    }

    event Listed(uint indexed listingId, address indexed seller, address nftContract, uint tokenId, uint price);
    event Sold(uint indexed listingId, address indexed buyer, uint price);
    event Cancelled(uint indexed listingId);

    constructor(uint _platformFee) {
        owner = msg.sender;
        platformFee = _platformFee;
    }

    mapping(uint => Listing) public Listings;

    function listNFT(address nftContract, uint tokenId, uint price) external {
        require(price > 0, "the price must be > 0");
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nft.transferFrom(msg.sender, address(this), tokenId);
        listCount++;
        Listings[listCount] = Listing(msg.sender, nftContract, tokenId, price, true);
        emit Listed(listCount, msg.sender, nftContract, tokenId, price);
    }

    function buyNFT(uint listingId) external payable {
        require(listingId <= listCount && listingId > 0, "This Listing doesn't exist");
        Listing storage listing = Listings[listingId];
        require(listing.active, "This Listing isn't active");
        require(msg.value == listing.price, "There is a mismatch in price");
        listing.active = false;
        (address royaltyReceiver, uint royaltyAmount) = IERC2981(listing.nftContract).royaltyInfo(listing.tokenId, msg.value);
        uint feeAmount = msg.value * platformFee / 10000;
        uint sellerAmount = msg.value - royaltyAmount - feeAmount;
        (bool sent1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        (bool sent2, ) = payable(owner).call{value: feeAmount}("");
        (bool sent3, ) = payable(listing.seller).call{value: sellerAmount}("");
        require(sent1 && sent2 && sent3, "Transfer Failed");
        IERC721 nft = IERC721(listing.nftContract);
        nft.transferFrom(address(this), msg.sender, listing.tokenId);
        emit Sold(listingId, msg.sender, listing.price);
    }

    function cancelListing(uint listingId) public {
        require(listingId <= listCount && listingId > 0, "This Listing doesn't exist");
        Listing storage listing = Listings[listingId];
        require(listing.active, "The Listing isn't active!");
        require(listing.seller == msg.sender, "Only the seller can cancel");
        listing.active = false;
        IERC721 nft = IERC721(listing.nftContract);
        nft.transferFrom(address(this), msg.sender, listing.tokenId);
        emit Cancelled(listingId);
    }
}