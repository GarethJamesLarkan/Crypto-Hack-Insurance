// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IInsurance {

    function addPolicyPayment(uint256 _amount, uint256 _policyId) external; 

    function getNumberOfPolicies(uint256 _policyId) external view returns (uint256);

    function getTotalLiquidity() external view returns(uint256);

    function getNumberOfLiquidityProviders() external view returns(uint256);

    function getPolicyValue(uint256 _policyId) external view returns (uint256);

    function addHack(uint256 _policyId, uint256 _amountPaid, bool _accepted) external;

} 