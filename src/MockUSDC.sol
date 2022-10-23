// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20{

    constructor() ERC20("Mock USDC", "MUSDC") {
        mint(msg.sender, 1000);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
