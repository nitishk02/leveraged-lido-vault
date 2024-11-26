// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for ERC20
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Interface for Uniswap Router
interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

contract UniswapAdapter {
    address public uniswapRouter;
    address public usdc;

    constructor(address _uniswapRouter, address _usdc) {
        uniswapRouter = _uniswapRouter;
        usdc = _usdc;
    }

    function swapUSDCtoETH(uint256 amount) external returns (uint256) {
        // Ensure the adapter has been approved to spend the USDC
        require(IERC20(usdc).balanceOf(msg.sender) >= amount, "Insufficient USDC balance");
        
        // Transfer USDC from sender to this contract
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);

        // Approve Uniswap router to spend USDC
        IERC20(usdc).approve(uniswapRouter, amount);

        // Define the path: USDC -> WETH -> ETH
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = IUniswapV2Router(uniswapRouter).WETH();

        // Perform the swap
        uint256[] memory amounts = IUniswapV2Router(uniswapRouter).swapExactTokensForETH(
            amount,
            0, // Accept any ETH amount (add slippage protection if required)
            path,
            msg.sender, // Send swapped ETH to the sender
            block.timestamp + 300 // Deadline for the transaction
        );

        return amounts[1]; // Return the amount of ETH received
    }
}
