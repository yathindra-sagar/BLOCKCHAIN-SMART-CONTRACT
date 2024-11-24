// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StakingContract {
    string public name = "Staking Token";
    string public symbol = "STAKE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf; // Tracks token balances
    mapping(address => uint256) public stakedBalance; // Tracks staked tokens
    mapping(address => uint256) public stakeStartTime; // Tracks when a user started staking
    mapping(address => uint256) public rewardsEarned; // Tracks rewards for each user

    uint256 public rewardRatePerSecond = 1; // Example reward rate (1 token per second for simplicity)

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply; // Assign all tokens to contract deployer initially
    }

    /// @notice Stake tokens to earn rewards
    /// @param amount The amount of tokens to stake
    function stake(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to stake");
        _updateRewards(msg.sender);

        // Transfer tokens to the staking balance
        balanceOf[msg.sender] -= amount;
        stakedBalance[msg.sender] += amount;
        stakeStartTime[msg.sender] = block.timestamp; // Record staking time
    }

    /// @notice Withdraw staked tokens and claim rewards
    /// @param amount The amount of tokens to withdraw
    function withdraw(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance to withdraw");
        _updateRewards(msg.sender);

        // Deduct tokens from staked balance and transfer back to the user
        stakedBalance[msg.sender] -= amount;
        balanceOf[msg.sender] += amount;
    }

    /// @notice Claim staking rewards
    function claimRewards() external {
        _updateRewards(msg.sender);

        uint256 reward = rewardsEarned[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Transfer rewards to the user
        rewardsEarned[msg.sender] = 0; // Reset rewards
        balanceOf[msg.sender] += reward; // Add rewards to user's balance
        totalSupply += reward; // Mint new tokens as rewards
    }

    /// @notice Internal function to update rewards for a user
    /// @param user The address of the user
    function _updateRewards(address user) internal {
        if (stakedBalance[user] > 0) {
            uint256 stakingDuration = block.timestamp - stakeStartTime[user];
            uint256 newRewards = stakingDuration * rewardRatePerSecond * stakedBalance[user] / (10 ** decimals);

            rewardsEarned[user] += newRewards;
            stakeStartTime[user] = block.timestamp; // Reset staking time
        }
    }

    /// @notice Get the total rewards earned by a user
    /// @param user The address of the user
    function calculateRewards(address user) external view returns (uint256) {
        if (stakedBalance[user] == 0) return rewardsEarned[user];

        uint256 stakingDuration = block.timestamp - stakeStartTime[user];
        uint256 newRewards = stakingDuration * rewardRatePerSecond * stakedBalance[user] / (10 ** decimals);

        return rewardsEarned[user] + newRewards;
    }

    // Fallback function to accept Ether and log it
    fallback() external payable {
        // Logic to handle Ether transfers when no function is matched
        emit EtherReceived(msg.sender, msg.value);
    }

    // Receive function to accept Ether with no data
    receive() external payable {
        // Logic to handle direct Ether transfers
        emit EtherReceived(msg.sender, msg.value);
    }

    // Event to log Ether transfers
    event EtherReceived(address indexed sender, uint256 amount);
}
