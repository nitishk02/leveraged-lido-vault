// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BorrowerManager {
    struct Position {
        uint256 collateral;
        uint256 borrowedAmount;
    }

    mapping(address => Position) public positions;

    function depositCollateral(address borrower, uint256 amount) external {
        require(amount >= 1000 * 1e6, "Minimum 1000 USDC required");
        positions[borrower].collateral += amount;
    }

    function getCollateral(address borrower) external view returns (uint256) {
        return positions[borrower].collateral;
    }

    function updateBorrowedAmount(address borrower, uint256 amount) external {
        positions[borrower].borrowedAmount += amount;
    }

    function getBorrowedAmount(address borrower) external view returns (uint256) {
        return positions[borrower].borrowedAmount;
    }
}
