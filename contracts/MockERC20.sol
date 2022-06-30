pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/Staking.sol";

contract MockERC20 is ERC20 {
    constructor () ERC20 ("MockERC20", "MOCK") {
        
    } 

    function mint(address user, uint256 amount) external {
        _mint(user, amount);
    }
}