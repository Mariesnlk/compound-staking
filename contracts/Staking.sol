// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IStaking.sol";
import "./mock/interfaces/ICEther.sol";

/// core stking without fee
contract Staking is IStaking, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @notice constant of minimum ether amount to stake
    uint256 private constant MIN_AMOUNT_TO_STAKE = 5 ether;
    /// @notice constant one day in seconds
    uint256 private constant DAY = 1 days;
    /// @notice constant 365 days in seconds
    uint256 private constant YEAR = 365 days;
    /// @notice annual percantage rate
    uint256 private constant APR = 10; // 10 %
    /// @notice contract to use data feeds from Chainlink
    AggregatorV3Interface public priceFeed;
    /// @notice contract to put staked ETH as collateral in Compound 
    ICEther public immutable CETH_TOKEN;
    /// @notice ERC20 token that claims as rewards
    IERC20 public immutable REWARD_TOKEN;
    /// @notice total amount of staked ETH
    uint256 public totalStakedAmount;
    /// @notice stakeholders info
    mapping(address => Stakeholder) public stakeholders;

    /// @notice constructor
    /// @param _cEtherToken - contract of cETH contract in Compound 
    /// @param _rewardToken - reward token address
    /// @param _priceFeed - contract address to connect to off-chain data
    ///
    /// Network: Goerli
    /// Aggregator: ETH/USD
    /// Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    constructor(address payable _cEtherToken, address _rewardToken, address _priceFeed) {
        require(_cEtherToken != address(0), "ZERO_ADDRESS");
        require(_rewardToken != address(0), "ZERO_ADDRESS");
        require(_priceFeed != address(0), "ZERO_ADDRESS");

        CETH_TOKEN = ICEther(_cEtherToken);
        REWARD_TOKEN = IERC20(_rewardToken);

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyStaker() {
        require(
            stakeholders[msg.sender].isStaked == true,
            "ONLY_STAKER_CAN_CALL"
        );
        _;
    }

    /// @notice staking ETH amount
    /// @dev every one can stake ETH to the staking pool
    function stake() public payable override nonReentrant {
        require(msg.value >= MIN_AMOUNT_TO_STAKE, "INVALID_AMOUNT");

        Stakeholder storage stakeholder = stakeholders[msg.sender];

        if (stakeholder.isStaked) {
            stakeholder.uclaimedRewards += _calculateReward(msg.sender);
        } else {
            stakeholder.isStaked = true;
        }

        stakeholders[msg.sender].lastUpdatedRewardTime = block.timestamp;
        stakeholder.stakedAmount += msg.value;
        totalStakedAmount += msg.value;

        // mint some cETH by supplying ETH to the Compound Protocol
        CETH_TOKEN.mint{ value: msg.value, gas: 250000 }();

        emit Staked(msg.sender, msg.value);
    }

    /// @notice withdrawing amount of staked ETH
    /// @dev only stakers can withdraw
    /// @param amount - ETH amount to withdraw staked ETH
    function withdraw(uint256 amount) external override onlyStaker {
        require(amount > 0 && amount <= stakeholders[msg.sender].stakedAmount, "INVALID_AMOUNT");

        stakeholders[msg.sender].uclaimedRewards += _calculateReward(msg.sender);
        stakeholders[msg.sender].stakedAmount -= amount;
        stakeholders[msg.sender].lastUpdatedRewardTime = block.timestamp;
        totalStakedAmount -= amount;

        // exchanging all cETH based on underlying ETH amount
        require(CETH_TOKEN.redeemUnderlying(amount) == 0, "FAILURED");

        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "INVALID_TRANSFER");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice claim rewards
    function claimReward() external override {
        uint256 reward = _calculateReward(msg.sender);

        stakeholders[msg.sender].uclaimedRewards = 0;
        stakeholders[msg.sender].lastUpdatedRewardTime = block.timestamp;

        (, int256 price, , , ) = priceFeed.latestRoundData();

        REWARD_TOKEN.transferFrom(owner(), msg.sender, reward * uint256(price));

        emit RewardClaimed(msg.sender, reward);
    }

    function _calculateReward(address _account) internal view returns (uint256) {
        return (((stakeholders[_account].stakedAmount * APR) / 100) / YEAR) * ((block.timestamp - stakeholders[_account].lastUpdatedRewardTime) / DAY);
    }

    receive() external payable {
        if (msg.sender != address(CETH_TOKEN) && msg.sender != address(0)) {
            stake();
        }
    }
}
