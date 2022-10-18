// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IInsurance {

    function addPolicyPayment(uint256 _amount, uint256 _policyId) external; 

    function getNumberOfPolicies(uint256 _policyId) external view returns (uint256);

} 