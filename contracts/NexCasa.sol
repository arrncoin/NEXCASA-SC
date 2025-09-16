// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract NexCasa is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @dev use address(0) for native token
    address public constant NATIVE = address(0);

    /// @dev user stakes: user => token => amount
    mapping(address => mapping(address => uint256)) private _stakes;

    /// @dev whitelist ERC20 tokens allowed for staking
    mapping(address => bool) public allowedTokens;

    /// @dev reward APY (scaled by 1e18, e.g., 10% = 0.10e18)
    mapping(address => uint256) public rewardAPY;

    /// @dev user reward tracking
    struct RewardData {
        uint256 rewardDebt;   // accumulated rewards not yet claimed
        uint256 lastUpdate;   // last timestamp rewards updated
    }
    mapping(address => mapping(address => RewardData)) private _rewards;

    event TokenAllowed(address token, bool status);
    event APYUpdated(address token, uint256 apy);
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardClaimed(address indexed user, address indexed token, uint256 reward);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) public initializer {
        __Ownable_init(owner_);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============ Admin functions ============

    function allowToken(address token, bool status) external onlyOwner {
        allowedTokens[token] = status;
        emit TokenAllowed(token, status);
    }

    function setAPY(address token, uint256 apy) external onlyOwner {
        // apy in 1e18, example: 10% = 0.1e18
        rewardAPY[token] = apy;
        emit APYUpdated(token, apy);
    }

    // ============ Internal Reward Logic ============

    function _updateRewards(address user, address token) internal {
        RewardData storage rd = _rewards[user][token];
        uint256 staked = _stakes[user][token];
        if (staked > 0) {
            uint256 timeDiff = block.timestamp - rd.lastUpdate;
            if (timeDiff > 0 && rewardAPY[token] > 0) {
                // reward = stake * APY * time / (365 days * 1e18)
                uint256 reward = (staked * rewardAPY[token] * timeDiff) / (365 days * 1e18);
                rd.rewardDebt += reward;
            }
        }
        rd.lastUpdate = block.timestamp;
    }

    // ============ User functions ============

    function stakeNative() external payable {
        require(msg.value > 0, "Zero stake");
        _updateRewards(msg.sender, NATIVE);
        _stakes[msg.sender][NATIVE] += msg.value;
        emit Staked(msg.sender, NATIVE, msg.value);
    }

    function stakeERC20(address token, uint256 amount) external {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Zero stake");
        _updateRewards(msg.sender, token);
        ERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
        _stakes[msg.sender][token] += amount;
        emit Staked(msg.sender, token, amount);
    }

    function unstakeNative(uint256 amount) external {
        require(_stakes[msg.sender][NATIVE] >= amount, "Insufficient balance");
        _updateRewards(msg.sender, NATIVE);
        _stakes[msg.sender][NATIVE] -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, NATIVE, amount);
    }

    function unstakeERC20(address token, uint256 amount) external {
        require(_stakes[msg.sender][token] >= amount, "Insufficient balance");
        _updateRewards(msg.sender, token);
        _stakes[msg.sender][token] -= amount;
        ERC20Upgradeable(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, token, amount);
    }

    function claimReward(address token) external {
        _updateRewards(msg.sender, token);
        uint256 reward = _rewards[msg.sender][token].rewardDebt;
        require(reward > 0, "No rewards");

        _rewards[msg.sender][token].rewardDebt = 0;

        if (token == NATIVE) {
            payable(msg.sender).transfer(reward);
        } else {
            ERC20Upgradeable(token).transfer(msg.sender, reward);
        }
        emit RewardClaimed(msg.sender, token, reward);
    }

    // ============ Views ============

    function stakedBalance(address user, address token) external view returns (uint256) {
        return _stakes[user][token];
    }

    function pendingReward(address user, address token) external view returns (uint256) {
        RewardData memory rd = _rewards[user][token];
        uint256 staked = _stakes[user][token];
        uint256 reward = rd.rewardDebt;
        if (staked > 0 && rewardAPY[token] > 0) {
            uint256 timeDiff = block.timestamp - rd.lastUpdate;
            reward += (staked * rewardAPY[token] * timeDiff) / (365 days * 1e18);
        }
        return reward;
    }
}
