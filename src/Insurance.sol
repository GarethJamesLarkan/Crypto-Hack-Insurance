// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;


import {console} from "forge-std/console.sol";

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
        uint256 id;
        uint256 safetyRating;
    }

    uint256 public numberOfPolicies = 0;
    uint256 public numberOfHoldingCompanies = 0;

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => HoldingCompany) public holdingCompanies;

    mapping(address => uint256) public numberOfPoliciesPerUser;

    constructor() {

    }

    function createHoldingCompany(uint256 _safetyRating) public {
        require(_safetyRating <= 100, "Invalid rating");

        holdingCompanies[numberOfHoldingCompanies] = HoldingCompany({
            id: numberOfHoldingCompanies,
            safetyRating: _safetyRating
        });

        numberOfHoldingCompanies++;
    }

    function createPolicy(uint256 _cryptoValueToBeInsured, HoldingCompany memory _company) public {
        uint256 installment = calculatePolicyInstallments(_cryptoValueToBeInsured, _company.id);
        
        policies[numberOfPolicies] = Policy({
            policyUniqueIdentifier: numberOfPolicies,
            policyValue: _cryptoValueToBeInsured,
            monthlyInstallment: installment,
            numberOfInstallments: 0,
            companyFundsInvestedIn: _company,
            owner: msg.sender
        });

        numberOfPoliciesPerUser[msg.sender] += 1;
        numberOfPolicies++;

    }

    function calculatePolicyInstallments(uint256 _value, uint256 _holdingCompanyId) public returns (uint256) {
        
        //If the user would pay the total value in 10 years of installments, what would they pay per month
        uint256 expected5YearInstallment = _value / 120;
        uint256 safetyAdjustment = 100 - holdingCompanies[_holdingCompanyId].safetyRating;
        uint256 policyInstallment = expected5YearInstallment + ((expected5YearInstallment * safetyAdjustment) / 100);

        return policyInstallment;
    }
    
    
}
