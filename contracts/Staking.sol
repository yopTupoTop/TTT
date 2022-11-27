pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Staking is Ownable, Pausable {
    
    IERC20 usdt;
    IERC20 ttt;

    uint256 constant CYCLE = 1 days;
    uint256 constant DAILY_REWARDS = 1000;

    struct Staker {
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 rewardAllowed;
        uint256 rewardDebt;
        uint256 distributed;
        uint256 unstakeAmount;
        uint256 unstakeTime;
    }

    mapping(address => Staker) public stakers;
    
    uint256 startTime;
    uint256 endTime;
    uint256 nextPay;
    uint256 stakeTimestamp;

    uint256 public rewardTotal;
    uint256 public unstakeLockTime;
    uint256 public totalStaked;
    uint256 public totalDistributed;

    uint256 public tokensPerStake;
    uint256 public allProduced;
    uint256 public produceTime;
    uint256 public rewardProduced;

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
        endTime = startTime + 30 days;
    }

    function produced() internal view returns (uint256) {
        return allProduced + (rewardTotal * (block.timestamp - produceTime) / CYCLE);
    }

    function updateReward() public whenStakingInProgress {
        uint256 rewardProducedAtNow = produced();
        if (rewardProducedAtNow > rewardProduced) {
            uint256 producedNew = rewardProducedAtNow - rewardProduced;
            if (totalStaked > 0) {
                tokensPerStake = tokensPerStake + 
                    (producedNew / totalStaked);
            }
            rewardProduced = rewardProduced + producedNew;
        }
    }

    function stake(uint128 _amount) external returns (uint256) {
        usdt.transferFrom(msg.sender, address(this), _amount);
        Staker storage staker = stakers[msg.sender];
        if(totalStaked > 0) {
            updateReward();
        }
        totalStaked += _amount;
        staker.stakeAmount += _amount;
        staker.rewardDebt += _amount * tokensPerStake;
        staker.stakeTime = block.timestamp;
        return staker.stakeTime;
    }

    function unstake(uint256 _amount) public {
        Staker storage staker = stakers[msg.sender];

        require(
            staker.stakeAmount >= _amount,
            "Staking: Not enough tokens to unstake"
        );

        updateReward();

        staker.rewardAllowed += _amount * tokensPerStake;

        staker.stakeAmount -= _amount;
        totalStaked -= _amount;

        staker.unstakeAmount += _amount;
        staker.unstakeTime = unstakeLockTime + block.timestamp;

    }

    function withdraw() public {
        Staker storage staker = stakers[msg.sender];

        require(
            staker.unstakeAmount > 0,
            "Staking: Not enough tokens to unstake"
        );

        require(
            block.timestamp >= staker.unstakeTime,
            "Staking: Unstaked tokens are not available yet."
        );

        uint256 amount = staker.unstakeAmount;
        staker.unstakeAmount = 0;
        staker.unstakeTime = 0;
        usdt.transfer(msg.sender, amount);
    }

    function claim() public returns (bool) {
        if (totalStaked > 0) {
            updateReward();
        }

        uint256 reward = calculateReward(msg.sender, tokensPerStake);
        require(reward > 0, "Staking: Nothing to claim");

        Staker storage staker = stakers[msg.sender];

        staker.distributed += reward;
        totalDistributed += reward;

        ttt.transfer(msg.sender, reward);
        return true;
    }

    function claimAndUnstake() public {
        Staker storage staker = stakers[msg.sender];
        unstake(staker.stakeAmount);

        uint256 reward = getReward(msg.sender);
        if (reward > 0) {
            claim();
        }
    }

    function calculateReward(address _staker, uint256 _tps) internal view returns (uint256 reward) {
        Staker storage staker = stakers[_staker];
        reward = staker.stakeAmount * _tps;
        return reward;
    }

    function getReward(address _staker) public view returns (uint256 reward) {
        uint256 tps = tokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow - rewardProduced;
                tps += producedNew / totalStaked;
            }
        }
        reward = calculateReward(_staker, tps);

        return reward;
    }
  }
