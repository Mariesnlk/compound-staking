// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStaking {
    struct Stakeholder {
        bool isStaked;
        uint256 stakedAmount;
        uint256 lastUpdatedRewardTime;
        uint256 uclaimedRewards;
    }

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardClaimed(address indexed user, uint256 reward);

    function stake() external payable;

    function withdraw(uint256 amount) external;

    function claimReward() external;

}
