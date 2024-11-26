// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

contract LidoAdapter {
    address public lido;

    constructor(address _lido) {
        lido = _lido;
    }

    function stakeETH(uint256 amount) external {
        require(amount > 0, "Invalid ETH amount");

        ILido(lido).submit{value: amount}(address(0));
    }
}
