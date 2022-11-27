// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IInsurance {

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------- STRUCTS -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    struct Policy {
        uint256 policyUniqueIdentifier;
        uint256 policyValue;
        uint256 monthlyInstallment;
        uint256 numberOfInstallments;
        uint256 valueOfInstallments;
        uint256 companyFundsInvestedIn;
        bool closed;
        address owner;
    }

    struct HoldingCompany {
        uint256 id;
        uint256 safetyRating;
    }

    struct Hack {
        uint256 hackId;
        uint256 policyId;
        uint256 amountPaidOut;
        bool accepted;
        uint256 timeOfPayout;
    }

    function addPolicyPayment(uint256 _amount, uint256 _policyId) external; 
    function updateHackAfterApproval(uint256 _hackId, uint256 _valueOfPolicy) external;
} 