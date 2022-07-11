// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IPangolinStake {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Recovered(address token, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function exit() external;

    function getReward() external;

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;

    function owner() external view returns (address);

    function periodFinish() external view returns (uint256);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function renounceOwnership() external;

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewards(address) external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function setRewardsDuration(uint256 _rewardsDuration) external;

    function stake(uint256 amount) external;

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount) external;
}
