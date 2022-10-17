// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

contract Insurance {

    struct Policy {
        uint256 policyUniqueIdentifier;
        uint256 policyValue;
        uint256 monthlyInstallment;
        uint256 numberOfInstallments;
        HoldingCompany companyFundsInvestedIn;
        address owner;
    }

    struct HoldingCompany {
        uint256 id,
        uint256 safetyRating
    }

    uint256 public numberOfPolicies;
    uint256 public numberOfHoldingCompanies;

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => HoldingCompany) public holdingCompanies;

    mapping(address => uint256) public numberOfPoliciesPerUser;

    constructor() {

    }

    function createPolicy(uint256 _cryptoValueToBeInsured, HoldingCompany _company) {
        
        uint256 installment = calculatePolicyInstallments(_cryptoValueToBeInsured, _company);
        
        policies[numberOfPolicies] = ({
            policyUniqueIdentifier = numberOfPolicies,
            policyValue = _cryptoValueToBeInsured,
            monthlyInstallment = installment,
            numberOfInstallments = 0,
            companyFundsInvestedIn = _company,
            owner = msg.sender
        });

        numberOfPoliciesPerUser[msg.sender] += 1;
        numberOfPolicies++;

    }

    function calculatePolicyInstallments(uint256 _value, HoldingCompany _company) internal returns (uint256) {
        
        //If the user would pay the total value in 5 years of installments, what would they pay per month
        uint256 expected5YearInstallment = _value / 60;
        uint256 safetyAdjustment = 100 - _company.safetyRating;
        uint256 policyInstallment = expected5YearInstallment + ((expected5YearInstallment * safetyAdjustment) / 100);

        return policyInstallment;
    }
    
    
}
