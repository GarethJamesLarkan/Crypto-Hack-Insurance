// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IInsurance {

    struct Hack {
        uint256 hackId;
        uint256 policyId;
        uint256 amountPaidOut;
        bool accepted;
        uint256 timeOfPayout;
    }

    function addPolicyPayment(uint256 _amount, uint256 _policyId) external; 

    function getNumberOfPolicies() external view returns (uint256);

    //function getTotalLiquidity() external view returns(uint256);

    //function getNumberOfLiquidityProviders() external view returns(uint256);

    function getPolicyValue(uint256 _policyId) external view returns (uint256);

    //function addHack(uint256 _policyId, uint256 _amountPaid, bool _accepted) external;

    function getPolicyOwner(uint256 _policyId) external view returns (address);

    function getHack(uint256 _hackId) external view returns(Hack memory);

    function updateHackAfterApproval(uint256 _hackId, uint256 _valueOfPolicy) external;


} 