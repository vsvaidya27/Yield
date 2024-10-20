// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract AavePool {
    // userAddr to asset to amount
    mapping (address => mapping (address => uint256)) public userDeposits;
    // Note - this is a simplified logic, do not use in production
    // this calculates a flat rate irrespective of when the deposit was done
    mapping (address => mapping (address => uint256)) public userDepositTime;

    function supply(address asset, uint256 amount, address onBehalfOf, uint256 referralCode) public payable {
        (asset, referralCode);
        userDeposits[onBehalfOf][0x0000000000000000000000000000000000000000] += amount;
        userDepositTime[onBehalfOf][0x0000000000000000000000000000000000000000] = block.timestamp;
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
        (bool sent,) = to.call{gas: 2300, value: amount}("");
        require(sent, "Failed to send tokens");
        // time is not updated here for resetting yields, to have fasters interests
    }
}

contract FlowConvertAndStake is Ownable {

    address usdcTokenAddress;
    uint256 exchangeRate;
    address supplyAddress;

    uint256 MAX_INT = 2**256 - 1;

    constructor (address _usdcTokenAddress, uint256 _exchangeRate, address _supplyAddress) {
        usdcTokenAddress = _usdcTokenAddress;
        exchangeRate = _exchangeRate;
        supplyAddress = _supplyAddress;
    }

    function updateExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }

    function convertAndStake(uint256 amount) public {
        IERC20(usdcTokenAddress).transferFrom(msg.sender, address(this), amount);
        uint256 flowAmount = exchangeRate * amount;
        AavePool(supplyAddress).supply(0x0000000000000000000000000000000000000000, flowAmount, msg.sender, 0);
    }

    function withdrawUSDC(uint256 amount) public onlyOwner {
        IERC20(usdcTokenAddress).transfer(msg.sender, amount);
    }

}

