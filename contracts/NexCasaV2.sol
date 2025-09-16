// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract NexCasaV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    /// @dev use address(0) for native token
    address public constant NATIVE = address(0);

    /// @dev user stakes: user => token => amount
    mapping(address => mapping(address => uint256)) private _stakes;

    /// @dev whitelist ERC20 tokens allowed for staking
    mapping(address => bool) public allowedTokens;

    /// @dev reward APY (scaled by 1e18)
    mapping(address => uint256) public rewardAPY;

    /// @dev user reward tracking
    struct RewardData {
        uint256 rewardDebt;   // accumulated rewards not yet claimed
        uint256 lastUpdate;   // last timestamp rewards updated
        uint256 lockupEnd;    // timestamp when lockup period ends
    }
    mapping(address => mapping(address => RewardData)) private _rewards;

    // ===================================
    // Tambahkan variabel baru di sini
    // ===================================

    // Data tambahan untuk fitur baru
    mapping(address => uint256) public stakeTier; // 1-3
    mapping(address => uint256) public lockupPeriod; // in seconds

    // Alamat token reward
    address public rewardToken;

    event TokenAllowed(address token, bool status);
    event APYUpdated(address token, uint256 apy);
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardClaimed(address indexed user, address indexed token, uint256 reward);
    event RewardTokenSet(address newRewardToken);
    event EmergencyWithdrawal(address indexed token, uint256 amount);
    event RewardAdded(address indexed token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) public initializer {
        __Ownable_init(owner_);
        __UUPSUpgradeable_init();
        __Pausable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============ Admin functions ============

    // Fungsi untuk menghentikan sementara kontrak
    function pause() external onlyOwner {
        _pause();
    }

    // Fungsi untuk melanjutkan kembali kontrak
    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address token) external onlyOwner {
        if (token == NATIVE) {
            uint256 nativeBalance = address(this).balance;
            require(nativeBalance > 0, "No native token balance to withdraw");
            payable(owner()).transfer(nativeBalance);
            emit EmergencyWithdrawal(NATIVE, nativeBalance);
        } else {
            uint256 tokenBalance = ERC20Upgradeable(token).balanceOf(address(this));
            require(tokenBalance > 0, "No ERC20 token balance to withdraw");
            ERC20Upgradeable(token).transfer(owner(), tokenBalance);
            emit EmergencyWithdrawal(token, tokenBalance);
        }
    }

    function addReward(address token, uint256 amount) external payable onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        if (token == NATIVE) {
            require(msg.value == amount, "Native token amount mismatch");
            emit RewardAdded(NATIVE, amount);
        } else {
            ERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
            emit RewardAdded(token, amount);
        }
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit RewardTokenSet(_rewardToken);
    }

    function allowToken(address token, bool status) external onlyOwner {
        allowedTokens[token] = status;
        emit TokenAllowed(token, status);
    }

    function setAPY(address token, uint256 apy) external onlyOwner {
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
                uint256 currentAPY = rewardAPY[token];
                if (rd.lockupEnd > 0) {
                    currentAPY = currentAPY * 120 / 100; // Contoh: bonus 20%
                }
                uint256 reward = (staked * currentAPY * timeDiff) / (365 days * 1e18);
                rd.rewardDebt += reward;
            }
        }
        rd.lastUpdate = block.timestamp;
    }

    // ============ User functions ============

    function stakeNative(uint256 lockupDurationInDays) external payable whenNotPaused {
        require(msg.value > 0, "Zero stake");
        _updateRewards(msg.sender, NATIVE);
        _stakes[msg.sender][NATIVE] += msg.value;
        _rewards[msg.sender][NATIVE].lockupEnd = block.timestamp + lockupDurationInDays * 1 days;
        emit Staked(msg.sender, NATIVE, msg.value);
    }

    function stakeERC20(address token, uint256 amount, uint256 lockupDurationInDays) external whenNotPaused {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Zero stake");
        _updateRewards(msg.sender, token);
        ERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
        _stakes[msg.sender][token] += amount;
        _rewards[msg.sender][token].lockupEnd = block.timestamp + lockupDurationInDays * 1 days;
        emit Staked(msg.sender, token, amount);
    }

    function unstakeNative(uint256 amount) external whenNotPaused {
        require(_stakes[msg.sender][NATIVE] >= amount, "Insufficient balance");
        require(block.timestamp >= _rewards[msg.sender][NATIVE].lockupEnd, "Lockup period not ended");
        _updateRewards(msg.sender, NATIVE);
        _stakes[msg.sender][NATIVE] -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, NATIVE, amount);
    }

    function unstakeERC20(address token, uint256 amount) external whenNotPaused {
        require(_stakes[msg.sender][token] >= amount, "Insufficient balance");
        require(block.timestamp >= _rewards[msg.sender][token].lockupEnd, "Lockup period not ended");
        _updateRewards(msg.sender, token);
        _stakes[msg.sender][token] -= amount;
        ERC20Upgradeable(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, token, amount);
    }

    // Fungsi baru untuk mengklaim reward saja
    function harvest(address token) external whenNotPaused {
        claimReward(token);
    }

    function claimReward(address token) internal {
        _updateRewards(msg.sender, token);
        uint256 reward = _rewards[msg.sender][token].rewardDebt;
        require(reward > 0, "No rewards");
        require(rewardToken != address(0), "Reward token not set");

        _rewards[msg.sender][token].rewardDebt = 0;

        if (rewardToken == NATIVE) {
            payable(msg.sender).transfer(reward);
        } else {
            ERC20Upgradeable(rewardToken).transfer(msg.sender, reward);
        }
        
        emit RewardClaimed(msg.sender, rewardToken, reward);
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
            uint256 currentAPY = rewardAPY[token];
            if (rd.lockupEnd > 0) {
                currentAPY = currentAPY * 120 / 100; // Bonus 20%
            }
            reward += (staked * currentAPY * timeDiff) / (365 days * 1e18);
        }
        return reward;
    }
}