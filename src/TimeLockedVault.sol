// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract TimeLockedVault {
    uint256 public constant LOCK_PERIOD = 20;

    struct LockedDeposit {
        uint256 amount;
        uint256 unlockBlock;
    }

    mapping(address => mapping(address => LockedDeposit)) public userBalances;

    function deposit (address token, uint256 amount, address user) external {
        IERC20(token). transferFrom(msg.sender, address(this), amount);

        userBalances[user][token] = LockedDeposit({
            amount : amount,
            unlockBlock : block.number + LOCK_PERIOD
        });
    }

    function withdraw(address token) external {
        LockedDeposit memory dep = userBalances[msg.sender][token];
        require(block.number >= dep.unlockBlock, "still locked");

        delete userBalances[msg.sender][token];
        IERC20(token).transfer(msg.sender, dep.amount);
    }
}