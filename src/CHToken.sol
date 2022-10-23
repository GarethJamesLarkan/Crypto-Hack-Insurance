// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CHToken is ERC20 {
    uint256 public maxSupply = 5000000;
    uint256 public maxPerWallet = 100000;
    IERC20 usdc;

    /**
    @notice Constructor
    @param _usdcAddress Address of the USDC token.
     */
    constructor(address _usdcAddress) ERC20("Crypto Hack Token", "CHT") {
        mint(msg.sender, 1000);
        usdc = IERC20(_usdcAddress);
    }

    /**
    @notice Mints CHTokens to sender
    @param to Address of the user recieving the tokens.
    @param amount The amount of tokens to mint at a $1 price.
     */
    function mint(address to, uint256 amount) public {
        require(_totalSupply() + amount <= maxSupply, "Max supply reached");
        require(
            _balances(to) + amount <= maxPerWallet,
            "Max per wallet reached"
        );

        usdc.transferFrom(msg.sender, address(this), amount);
        _mint(to, amount);
    }
}
