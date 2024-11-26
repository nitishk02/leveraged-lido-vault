// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAave {
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

contract AaveAdapter {
    address public aavePool;
    address public usdc;

    constructor(address _aavePool, address _usdc) {
        aavePool = _aavePool;
        usdc = _usdc;
    }

    // Borrow USDC from Aave on behalf of the vault
    function borrow(address onBehalfOf, uint256 amount) external {
        IAave(aavePool).borrow(usdc, amount, 2, 0, onBehalfOf);
    }

    // Calculate the borrower's health factor
    function getHealthFactor(uint256 collateral, uint256 debt) external view returns (uint256) {
        // Assume liquidation threshold of 80%
        uint256 liquidationThreshold = 80; // 80%
        uint256 healthFactor = (collateral * liquidationThreshold) / debt;
        return healthFactor;
    }
}
