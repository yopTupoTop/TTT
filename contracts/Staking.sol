pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {
    
    IERC20 usdt;
    IERC20 ttt;

    uint256 constant CYCLE = 1 days;
    uint256 constant DAILY_REWARDS = 1000;

    struct Stake {
        uint256 timestamp;
        uint128 amount;
        uint256 index;
    }
    struct Reward {
        uint256 timestamp;
        uint256 amount;
    }

    mapping (address => Stake) stakes;
    mapping (address => Reward) rewards;

    address[] stakeholders;

    uint256 startTime;
    uint256 endTime;
    uint256 nextPay;

    modifier whenStakingInProgress () {
        uint256 currentTime = block.timestamp;
        require(currentTime >= startTime && currentTime < endTime, "staking is not in progress");
        _;    
    }

    constructor(address _usdt, address _ttt) {
        usdt = IERC20(_usdt);
        ttt = IERC20(_ttt);
    }

    function start(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function createStake(uint128 amount) external {
        usdt.transferFrom(msg.sender, address(this), amount);
        uint256 stakeTime = block.timestamp;
        stakeholders.push(msg.sender);
        stakes[msg.sender] = Stake(stakeTime, amount, stakeholders.length);
    }

    function removeStake(uint128 amount) external {
        usdt.transfer(msg.sender, amount);
        uint256 _index = stakes[msg.sender].index;
        if (_index == stakeholders.length - 1) {
            stakeholders.pop();
        } else {
            stakeholders[_index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            delete stakes[msg.sender];
        }
    }

    function calculateReward() internal whenStakingInProgress {
        uint256 totalRewards;
        uint256 currentTime = block.timestamp;
        for (uint256 i= 0; i < stakeholders.length; i++) {
            totalRewards += stakes[stakeholders[i]].amount;
        }
        uint256 reward = (stakes[msg.sender].amount / totalRewards) * DAILY_REWARDS * 
        (stakes[msg.sender].timestamp / (currentTime - rewards[msg.sender].timestamp + CYCLE));
        rewards[msg.sender] = Reward(currentTime, reward);
    }

    function getReward() external {
        require (stakeholders[stakes[msg.sender].index] == msg.sender);
        uint256 rewardAmount = rewards[msg.sender].amount;
        if ((block.timestamp - rewards[msg.sender].timestamp) > CYCLE) {
            calculateReward();    
        }
        ttt.transfer(msg.sender, rewardAmount);
    }
}