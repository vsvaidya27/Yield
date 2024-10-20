// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AavePool {
    // userAddr to asset to amount
    mapping (address => mapping (address => uint256)) public userDeposits;
    // Note - this is a simplified logic, do not use in production
    // this calculates a flat rate irrespective of when the deposit was done
    mapping (address => mapping (address => uint256)) public userDepositTime;

    function supply(address asset, uint256 amount, address onBehalfOf, uint256 referralCode) public {
        (referralCode);
        IERC20(asset).transferFrom(onBehalfOf, address(this), amount);
        userDeposits[onBehalfOf][asset] += amount;
        userDepositTime[onBehalfOf][asset] = block.timestamp;
    }

    function getBalance(address asset, address onBehalfOf) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - userDepositTime[onBehalfOf][asset];
        uint256 totalYield = (userDeposits[onBehalfOf][asset] * 1 * timeElapsed) / 10000;
        return totalYield + userDeposits[onBehalfOf][asset];
    }

    function withdraw(address asset, uint256 amount, address to) public {
        // update users balance to the yeild added balance
        userDeposits[msg.sender][asset] = getBalance(asset, msg.sender);
        require(userDeposits[msg.sender][asset] >= amount, "Insufficient Deposit");
        userDeposits[msg.sender][asset] -= amount;
        IERC20(asset).transfer(to, amount);
        // time is not updated here for resetting yields, to have fasters interests
    }
}