// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IFundManager {

    function getTotalLiquidity() external view returns (uint256);

    function distributeHackFunds(address _to, uint256 _amount) external;

} 