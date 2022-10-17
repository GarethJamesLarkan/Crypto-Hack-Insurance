// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CHToken is ERC20{

    constructor() ERC20("CryptoHack Token", "CHT") {

        mint(msg.sender, 1000);

    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
    
    
}
