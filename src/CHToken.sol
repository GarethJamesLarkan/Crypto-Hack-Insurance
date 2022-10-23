// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract CHToken is ERC20 {
    uint256 public maxSupply = 5000000;
    uint256 public maxPerWallet = 100000;

    constructor() ERC20("Crypto Hack Token", "CHT") {
        mint(msg.sender, 1000);
    }

    function mint(address to, uint256 amount) public {
        require(_totalSupply() + amount <= maxSupply, "Max supply reached");
        require(
            _balances(to) + amount <= maxPerWallet,
            "Max per wallet reached"
        );

        _mint(to, amount);
    }
}
