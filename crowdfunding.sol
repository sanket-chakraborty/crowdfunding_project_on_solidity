// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";

contract crowdfunding {
    struct Campaign {
        uint256 id;
        uint256 goal;
        uint256 amountRaised;
        uint256 campaignClosing;
        address payable manager;
        bool onGoing;
        mapping(address => uint256) contributions;
    }

    MyToken public token;
    uint256 public idInc;
    mapping(uint256 => Campaign) public campaigns;

    constructor(address _token) {
        token = MyToken(_token);
        idInc = 1;
    }

    function createCampaign(uint256 goal, uint256 duration) public {
        require(goal > 0, "Enter a valid goal amount");
        campaigns[idInc].id = idInc;
        campaigns[idInc].goal = goal;
        campaigns[idInc].amountRaised = 0;
        campaigns[idInc].campaignClosing = duration+ block.timestamp;
        campaigns[idInc].manager = payable(msg.sender);
        campaigns[idInc].onGoing = true;

        idInc++;
    }

    function contribute(uint256 idInput, uint256 amount) public payable {
        Campaign storage campaign = campaigns[idInput];
        require(campaign.id > 0, "Enter a valid campaign ID.");
        require(campaign.onGoing, "Campaign is over.");
        require(
            msg.sender != campaign.manager,
            "The creator of the campaign cannot contribute."
        );
        require(amount > 0, "Contribute a valid amount.");

        token.transferFrom(msg.sender, address(this), amount);

        campaign.amountRaised += amount;
        campaign.contributions[msg.sender] += amount;
    }

    function cancelContribution(uint256 idInput) public {
        Campaign storage campaign = campaigns[idInput];
        require(
            campaign.contributions[msg.sender] > 0,
            "You haven't made any contributions."
        );
        require(campaign.id > 0, "Enter a valid campaign ID.");
        require(campaign.onGoing, "Campaign is over.");

        uint256 amount = campaign.contributions[msg.sender];
        campaign.amountRaised -= amount;
        campaign.contributions[msg.sender] = 0;

        token.transfer(msg.sender, amount);
    }

    function withdrawFunds(uint256 idInput) public {
        Campaign storage campaign = campaigns[idInput];
        require(!campaign.onGoing, "Campaign is not yet over.");
        require(campaign.amountRaised >= campaign.goal, "Goal not met.");
        require(campaign.id > 0, "Enter a valid Campaign ID.");
        require(
            msg.sender == campaign.manager,
            "You are not the creator of the campaign."
        );

        campaign.manager.transfer(token.balanceOf(address(this)));
        campaign.onGoing = false;
    }

    function refund(uint256 idInput) public {
        Campaign storage campaign = campaigns[idInput];
        require(campaign.id > 0, "Enter a valid Campaign ID.");
        require(!campaign.onGoing, "Campaign is not yet over.");
        require(campaign.amountRaised < campaign.goal, "Goal was met.");
        require(
            campaign.contributions[msg.sender] > 0,
            "You have not made any contributions."
        );

        uint256 amount = campaign.contributions[msg.sender];
        campaign.contributions[msg.sender] = 0;

        token.transfer(msg.sender, amount);
    }
}
