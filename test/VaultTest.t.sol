// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/LenderManager.sol";
import "../src/BorrowerManager.sol";
import "../src/adapters/AaveAdapter.sol";
import "../src/adapters/UniswapAdapter.sol";
import "../src/adapters/LidoAdapter.sol";


contract VaultTest is Test {
    Vault public vault;
    LenderManager public lenderManager;
    BorrowerManager public borrowerManager;
    AaveAdapter public aaveAdapter;
    UniswapAdapter public uniswapAdapter;
    LidoAdapter public lidoAdapter;

    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Mocked USDC token address
    address public aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // Mocked Aave pool
    address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Mocked Uniswap router
    address public lido = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // Mocked Lido address

    address public borrower = address(0x123);
    address public lender = address(0x456);

    function setUp() public {
        // Deploy manager and adapter contracts
        lenderManager = new LenderManager();
        borrowerManager = new BorrowerManager();
        aaveAdapter = new AaveAdapter(aavePool, usdc);
        uniswapAdapter = new UniswapAdapter(uniswapRouter, usdc);
        lidoAdapter = new LidoAdapter(lido);

        // Deploy Vault contract
        vault = new Vault(
            address(lenderManager),
            address(borrowerManager),
            address(aaveAdapter),
            address(uniswapAdapter),
            address(lidoAdapter)
        );

        // Provide USDC to borrower and lender for testing
        deal(usdc, borrower, 10000 * 1e6); // 10,000 USDC to borrower
        deal(usdc, lender, 20000 * 1e6);  // 20,000 USDC to lender
    }

    // Test 1: Deposit Collateral
    function testDepositCollateral() public {
        vm.startPrank(borrower);

        // Approve and deposit 1000 USDC as collateral
        IERC20(usdc).approve(address(borrowerManager), 1000 * 1e6);
        borrowerManager.depositCollateral(borrower, 1000 * 1e6);

        uint256 collateral = borrowerManager.getCollateral(borrower);
        assertEq(collateral, 1000 * 1e6); // Collateral is correctly updated

        vm.stopPrank();
    }

    // Test 2: Lender Delegation
    function testLenderDelegation() public {
        vm.startPrank(lender);

        // Lender delegates 5000 USDC
        lenderManager.delegateBorrowingPower(5000 * 1e6, 1 ether);

        (uint256 delegatedAmount, uint256 usedAmount, uint256 minHealthFactor) = lenderManager.lenders(lender);
        assertEq(delegatedAmount, 5000 * 1e6);
        assertEq(usedAmount, 0);
        assertEq(minHealthFactor, 1 ether); // Health factor is set correctly

        vm.stopPrank();
    }

    // Test 3: Open Leveraged Position
    function testOpenLeveragedPosition() public {
        // Lender delegates 5000 USDC
        vm.startPrank(lender);
        lenderManager.delegateBorrowingPower(5000 * 1e6, 1 ether);
        vm.stopPrank();

        // Borrower deposits 1000 USDC as collateral
        vm.startPrank(borrower);
        IERC20(usdc).approve(address(borrowerManager), 1000 * 1e6);
        borrowerManager.depositCollateral(borrower, 1000 * 1e6);

        // Open leveraged position
        vault.openLeveragedPosition(borrower);

        uint256 collateral = borrowerManager.getCollateral(borrower);
        uint256 borrowedAmount = borrowerManager.getBorrowedAmount(borrower);

        assertEq(collateral, 1000 * 1e6);
        assertEq(borrowedAmount, 5000 * 1e6); // 5x leverage

        vm.stopPrank();
    }

    // Test 4: Health Factor Monitoring
    function testHealthFactor() public {
        // Lender delegates 5000 USDC
        vm.startPrank(lender);
        lenderManager.delegateBorrowingPower(5000 * 1e6, 1 ether);
        vm.stopPrank();

        // Borrower deposits 1000 USDC as collateral
        vm.startPrank(borrower);
        IERC20(usdc).approve(address(borrowerManager), 1000 * 1e6);
        borrowerManager.depositCollateral(borrower, 1000 * 1e6);

        // Open leveraged position
        vault.openLeveragedPosition(borrower);

        uint256 healthFactor = vault.getHealthFactor(borrower);
        assertTrue(healthFactor >= 1 ether); // Ensure health factor is acceptable

        vm.stopPrank();
    }

    // Test 5: Insufficient Delegation
    function testInsufficientDelegation() public {
        // Borrower deposits 1000 USDC as collateral
        vm.startPrank(borrower);
        IERC20(usdc).approve(address(borrowerManager), 1000 * 1e6);
        borrowerManager.depositCollateral(borrower, 1000 * 1e6);

        // Attempt to open a leveraged position without sufficient delegation
        vm.expectRevert("Insufficient credit");
        vault.openLeveragedPosition(borrower);

        vm.stopPrank();
    }

    // Test 6: Edge Case - Deposit Less Than Minimum Collateral
    function testDepositLessThanMinimumCollateral() public {
        vm.startPrank(borrower);

        // Attempt to deposit less than 1000 USDC
        vm.expectRevert("Minimum 1000 USDC required");
        borrowerManager.depositCollateral(borrower, 500 * 1e6);

        vm.stopPrank();
    }
}
