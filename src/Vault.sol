// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LenderManager.sol";
import "./BorrowerManager.sol";
import "./adapters/AaveAdapter.sol";
import "./adapters/UniswapAdapter.sol";
import "./adapters/LidoAdapter.sol";

contract Vault {
    LenderManager public lenderManager;
    BorrowerManager public borrowerManager;
    AaveAdapter public aaveAdapter;
    UniswapAdapter public uniswapAdapter;
    LidoAdapter public lidoAdapter;

    uint256 public constant LEVERAGE_FACTOR = 5; // 5x Leverage

    constructor(
        address _lenderManager,
        address _borrowerManager,
        address _aaveAdapter,
        address _uniswapAdapter,
        address _lidoAdapter
    ) {
        lenderManager = LenderManager(_lenderManager);
        borrowerManager = BorrowerManager(_borrowerManager);
        aaveAdapter = AaveAdapter(_aaveAdapter);
        uniswapAdapter = UniswapAdapter(_uniswapAdapter);
        lidoAdapter = LidoAdapter(_lidoAdapter);
    }

    function openLeveragedPosition(address borrower) external {
        uint256 collateral = borrowerManager.getCollateral(borrower);
        require(collateral > 0, "No collateral provided");

        uint256 borrowAmount = collateral * LEVERAGE_FACTOR;
        uint256 totalBorrowed = lenderManager.allocateCredit(borrower, borrowAmount);

        uint256 ethAmount = uniswapAdapter.swapUSDCtoETH(totalBorrowed);
        lidoAdapter.stakeETH(ethAmount);

        borrowerManager.updateBorrowedAmount(borrower, totalBorrowed);
    }

    function getHealthFactor(address borrower) external view returns (uint256) {
        uint256 collateral = borrowerManager.getCollateral(borrower);
        uint256 debt = borrowerManager.getBorrowedAmount(borrower);

        return aaveAdapter.getHealthFactor(collateral, debt);
    }
}
