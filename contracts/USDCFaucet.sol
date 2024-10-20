// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDCFaucet {

    address public tokenAddress;

    // 0.1 USDC
    uint256 public constant DRIP = 100000;

    constructor (address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) public {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    }

    function get() public {
        IERC20(tokenAddress).transfer(msg.sender, DRIP);
    }
}