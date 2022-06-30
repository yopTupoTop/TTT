pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/Staking.sol";

contract TTT is ERC20 {
    constructor () ERC20 ("Test Task Token", "TTT") {
        
    } 
}