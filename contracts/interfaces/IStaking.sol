// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStaking {
    /// @notice Struct stakeholders info
    /// @param isStaked - true if stakeholder aready staked
    /// @param stakedAmount - number of tokens that stakeholder staked
    /// @param lastUpdatedRewardTime - timestamp when stakeholder last time unstaked
    /// @param uclaimedRewards - reward amount that stakeholder can claim
    struct Stakeholder {
        bool isStaked;
        uint256 stakedAmount;
        uint256 lastUpdatedRewardTime;
        uint256 uclaimedRewards;
    }

    /// @notice This event is emitted when a stakeholder stake amount of ETH.
    /// @param sender - address of the stakeholder
    /// @param amount - ETH to stake
    event Staked(address indexed sender, uint256 amount);

    /// @notice This event is emitted when a stakeholder wants to withdraw his staked tokens.
    /// @param recipient - address of the stakeholder
    /// @param amount - number of ETH to unstake (that were staked before)
    event Withdrawn(address indexed recipient, uint256 amount);

    /// @notice This event is emitted when a stakeholder wants to withdraw his rewards.
    /// @param recipient - address of the stakeholder
    /// @param reward - number of tokens for reward
    event RewardClaimed(address indexed recipient, uint256 reward);

    /// @notice staking ETH amount
    /// @dev every one can stake ETH to the staking pool
    function stake() external payable;

    /// @notice withdrawing amount of staked ETH
    /// @dev only stakers can withdraw
    /// @param amount - ETH amount to withdraw staked ETH
    function withdraw(uint256 amount) external;

    /// @notice claim rewards
    function claimReward() external;
}
