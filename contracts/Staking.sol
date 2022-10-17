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
    /// @notice
    uint256 private constant MIN_AMOUNT_TO_STAKE = 5 ether;
    /// @notice
    uint256 private constant DAY = 1 days;
    /// @notice
    uint256 private constant YEAR = 365 days;
    /// @notice
    uint256 private constant APR = 10; // 10 %
    /// @notice
    AggregatorV3Interface public priceFeed;
    /// @notice
    ICEther public immutable CETH_TOKEN;
    /// @notice
    IERC20 public immutable REWARD_TOKEN;
    /// @notice
    uint256 public totalStakedAmount;
    /// @notice stakeholders info
    mapping(address => Stakeholder) public stakeholders;

    /// @notice constructor
    /// @param _cEtherToken - 
    /// @param _rewardToken - reward token address
    /// @param _priceFeed - 
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

        CETH_TOKEN.mint{ value: msg.value, gas: 250000 }();

        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override onlyStaker {
        require(amount > 0 && amount <= stakeholders[msg.sender].stakedAmount, "INVALID_AMOUNT");

        stakeholders[msg.sender].uclaimedRewards += _calculateReward(msg.sender);
        stakeholders[msg.sender].stakedAmount -= amount;
        stakeholders[msg.sender].lastUpdatedRewardTime = block.timestamp;
        totalStakedAmount -= amount;

        require(CETH_TOKEN.redeemUnderlying(amount) == 0, "FAILURED");

        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "INVALID_TRANSFER");

        emit Withdrawn(msg.sender, amount);
    }

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
