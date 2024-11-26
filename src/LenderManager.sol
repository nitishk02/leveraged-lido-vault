// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LenderManager {
    struct Lender {
        uint256 delegatedAmount;
        uint256 usedAmount;
        uint256 minHealthFactor;
    }

    mapping(address => Lender) public lenders;
    address[] public lenderList;

    function delegateBorrowingPower(uint256 amount, uint256 minHF) external {
        require(amount > 0, "Invalid amount");
        require(minHF >= 1 ether, "Min HF must be >= 1");

        lenders[msg.sender] = Lender(amount, 0, minHF);
        lenderList.push(msg.sender);
    }

    function allocateCredit(address borrower, uint256 amount) external returns (uint256 totalBorrowed) {
        totalBorrowed = 0;

        for (uint256 i = 0; i < lenderList.length; i++) {
            address lender = lenderList[i];
            Lender storage lenderInfo = lenders[lender];

            if (lenderInfo.delegatedAmount > lenderInfo.usedAmount) {
                uint256 available = lenderInfo.delegatedAmount - lenderInfo.usedAmount;

                uint256 borrowFromLender = available > amount ? amount : available;
                lenderInfo.usedAmount += borrowFromLender;
                totalBorrowed += borrowFromLender;

                amount -= borrowFromLender;

                if (amount == 0) break;
            }
        }

        require(totalBorrowed >= amount, "Insufficient credit");
    }
}
