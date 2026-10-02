// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfund {

    struct Campaign {
        address creator;
        uint goal;
        uint deadline;
        uint totalFunded;
        bool claimed;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    function createCampaign(uint goal, uint duration) external {
        require(goal > 0, "Goal must be > 0");
        require(duration > 0, "Duration must be > 0");
        campaignCount++;
        campaigns[campaignCount].creator = msg.sender;
        campaigns[campaignCount].goal = goal;
        campaigns[campaignCount].deadline = block.timestamp + duration;
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory Camps = new Campaign[](campaignCount);
        for (uint i = 1; i <= campaignCount; i++) {
            Camps[i - 1] = campaigns[i];
        }
        return Camps;
    }

    function getCampaign(uint id) external view returns (Campaign memory) {
        require(id > 0 && id <= campaignCount, "Campaign doesn't exist");
        return campaigns[id];
    }

    function contribute(uint campaignId) external payable {
        require(campaignId > 0 && campaignId <= campaignCount, "Campaign doesn't exist");
        require(msg.value > 0, "Money must be > 0");
        require(block.timestamp < campaigns[campaignId].deadline, "Deadline has passed no contribution accepted");
        Campaign storage campaign = campaigns[campaignId];
        campaign.totalFunded += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
    }

    function withdraw(uint campaignId) external {
        require(campaignId > 0 && campaignId <= campaignCount, "Campaign doesn't exist");
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender, "You must be the creator of this campaign to withdraw the money");
        require(campaign.goal <= campaign.totalFunded, "You didn't achieve the goal yet!!!!");
        require(block.timestamp >= campaign.deadline, "The Deadline isn't there yet!!!");
        require(!campaign.claimed, "The Fund it's already cleamed");
        campaign.claimed = true;
        (bool sent, ) = payable(msg.sender).call{value: campaign.totalFunded}("");
        require(sent, "The transfer failed everything is reverted");
    }

    function refund(uint campaignId) external {
        require(campaignId > 0 && campaignId <= campaignCount, "Campaign doesn't exist");
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.deadline, "The deadline isn't finished yet!!");
        require(campaign.goal > campaign.totalFunded, "The Goal is achieved you can't refund the funds!!");
        require(contributions[campaignId][msg.sender] > 0, "You didn't put any funds to refund!!");
        uint amount = contributions[campaignId][msg.sender];
        contributions[campaignId][msg.sender] = 0;
        campaign.totalFunded -= amount;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "The transfer failed everything is reverted");
    }
}