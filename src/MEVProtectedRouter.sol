// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IVault {
    function deposit(address token, uint256 amount, address recipient) external;
}

contract MEVProtectedRouter {
    error CooldownActive();
    error SlippageExceeded();

    uint256 public constant COOLDOWN = 10; // blocks
    struct SwapIntent {
        address user;
        address tokenIn;
        uint256 amountIn;
        address vault;
        uint256 minOut;
        uint256 createdAt;
    }

    mapping(bytes32 => SwapIntent) public swaps;

    event SwapRequested(bytes32 indexed id, address user, address tokenIn, uint256 amountIn);
    event SwapExecuted(bytes32 indexed id, address vault, uint256 received);
    

    function requestSwap(
        address tokenIn,
        uint256 amountIn,
        address vault,
        uint256 minOut
    ) external returns (bytes32 id) {
        IERC20(tokenIn). transferFrom(msg.sender, address(this), amountIn);

        id = keccak256(abi.encodePacked(msg.sender, tokenIn, amountIn, vault, block.number));

        swaps[id] = SwapIntent({
            user : msg.sender,
            tokenIn : tokenIn,
            amountIn : amountIn,
            vault : vault,
            minOut : minOut,
            createdAt : block.number
        });

        emit SwapRequested(id, msg.sender, tokenIn, amountIn);

    }

    function executeSwap(bytes32 id, uint256 actualOut) external {
        SwapIntent memory swap = swaps[id];
        if(block.number < swap.createdAt + COOLDOWN) revert CooldownActive();
        if(actualOut < swap.minOut) revert SlippageExceeded();

        IERC20(swap.tokenIn).approve(swap.vault,swap.amountIn);
        IVault(swap.vault).deposit(swap.tokenIn, swap.amountIn, swap.user);

        delete swaps[id];
        emit SwapExecuted(id, swap.vault, actualOut);
    }
}