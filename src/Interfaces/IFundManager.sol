// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IFundManager {

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------- STRUCTS ----------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    function distributeHackFunds(address _to, uint256 _amount) external;

} 