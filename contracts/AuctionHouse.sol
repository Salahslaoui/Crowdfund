// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AuctionHouse {

    uint public auctionCount;
    uint public platformFee;
    address public owner;

    struct Auction {
        address seller;
        address nftContract;
        uint tokenId;
        uint startingPrice;
        uint deadline;
        address highestbider;
        uint highestbid;
        bool complete;
    }

    constructor(uint _platformFee) {
        platformFee = _platformFee;
        owner = msg.sender;
    }

    mapping(uint => Auction) public Auctions;

    event AuctionStarted(uint indexed auctionId, address indexed seller, uint startingPrice, uint deadline);
    event BidPlaced(uint indexed auctionId, address indexed bidder, uint amount);
    event AuctionEnded(uint indexed auctionId, address indexed winner, uint amount);
    event AuctionCanceled(uint indexed auctionId);

    function StartAuction(address nftContract, uint tokenId, uint startingPrice, uint deadline) external {
        require(startingPrice > 0, "the starting price must be greater than 0");
        require(deadline > 0, "the deadline must be greater than 0");
        auctionCount++;
        Auction storage Auc = Auctions[auctionCount];
        Auc.seller = msg.sender;
        Auc.nftContract = nftContract;
        Auc.tokenId = tokenId;
        Auc.deadline = block.timestamp + deadline;
        Auc.highestbid = startingPrice;
        Auc.startingPrice = startingPrice;
        Auc.complete = false;
        IERC721 nft = IERC721(nftContract);
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit AuctionStarted(auctionCount, Auc.seller, Auc.startingPrice, Auc.deadline);
    }

    function bid(uint auctionId) payable external {
        require(auctionId > 0 && auctionId <= auctionCount, "This auction doesn't exist");
        Auction storage Auc = Auctions[auctionId];
        require(Auc.highestbid < msg.value, "You need to bid with higher value than the previous one");
        require(Auc.complete == false, "This bid is already completed");
        require(block.timestamp < Auc.deadline, "The deadline has already passed!!!");
        address previousBidder = Auc.highestbider;
        uint previouseBid = Auc.highestbid;
        Auc.highestbider = msg.sender;
        Auc.highestbid = msg.value;
        if (previousBidder != address(0)) {
            (bool sent, ) = payable(previousBidder).call{value: previouseBid}("");
            require(sent, "Refund Failed");
        }
        emit BidPlaced(auctionId, Auc.highestbider, Auc.highestbid);
    }

    function endAuction(uint auctionId) external {
        require(auctionId > 0 && auctionId <= auctionCount, "This auction doesn't exist");
        Auction storage Auc = Auctions[auctionId];
        require(msg.sender == Auc.seller, "Only the seller can end the auction");
        require(block.timestamp >= Auc.deadline, "The Deadline didn't finish yet");
        require(Auc.complete == false, "This bid is already completed");
        require(Auc.highestbider != address(0), "No bids placed, cancel instead!!");
        IERC721 nft = IERC721(Auc.nftContract);
        Auc.complete = true;
        (address royaltyReceiver, uint royaltyAmount) = IERC2981(Auc.nftContract).royaltyInfo(Auc.tokenId, Auc.highestbid);
        uint feeAmount = Auc.highestbid * platformFee / 10000;
        uint amount = Auc.highestbid - royaltyAmount - feeAmount;
        (bool sent, ) = payable(Auc.seller).call{value: amount}("");
        (bool sent1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        (bool sent2, ) = payable(owner).call{value: feeAmount}("");
        require(sent && sent1 && sent2, "Transfer Failed");
        nft.transferFrom(address(this), Auc.highestbider, Auc.tokenId);
        emit AuctionEnded(auctionId, Auc.highestbider, Auc.highestbid);
    }

    function cancelAuction(uint auctionId) external {
        require(auctionId > 0 && auctionId <= auctionCount, "This auction doesn't exist");
        Auction storage Auc = Auctions[auctionId];
        require(Auc.highestbider == address(0), "You have the right to cancel only if nobody has bidded yet!");
        require(Auc.complete == false, "This auction is already completed");
        require(msg.sender == Auc.seller, "You have to be the seller to cancel!!!");
        Auc.complete = true;
        IERC721 nft = IERC721(Auc.nftContract);
        nft.transferFrom(address(this), Auc.seller, Auc.tokenId);
        emit AuctionCanceled(auctionId);
    }
}

