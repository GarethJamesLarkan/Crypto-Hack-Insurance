// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import {console} from "forge-std/console.sol";
import "./Interfaces/IFundManager.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract Insurance {

    IFundManager manager;
    IERC20 usdc;

    struct Policy {
        uint256 policyUniqueIdentifier;
        uint256 policyValue;
        uint256 monthlyInstallment;
        uint256 numberOfInstallments;
        uint256 valueOfInstallments;
        uint256 companyFundsInvestedIn;
        address owner;
    }

    struct HoldingCompany {
        uint256 id;
        uint256 safetyRating;
    }

    uint256 public numberOfPolicies;
    uint256 public numberOfHoldingCompanies;

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => HoldingCompany) public holdingCompanies;

    mapping(address => uint256) public numberOfPoliciesPerUser;

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
    }

    function addPolicyPayment(uint256 _amount, uint256 _policyId) public {
        require(_amount == policies[_policyId].monthlyInstallment, "Incorrect payment amount");

        policies[_policyId].numberOfInstallments++;
        policies[_policyId].valueOfInstallments += _amount;

    }

    function createHoldingCompany(uint256 _safetyRating) public {
        require(_safetyRating <= 100, "Invalid rating");

        holdingCompanies[numberOfHoldingCompanies] = HoldingCompany({
            id: numberOfHoldingCompanies,
            safetyRating: _safetyRating
        });

        numberOfHoldingCompanies++;
    }

    function createPolicy(uint256 _cryptoValueToBeInsured, uint256 _holdingCompanyId) public {
        uint256 installment = calculatePolicyInstallments(_cryptoValueToBeInsured, _holdingCompanyId);
        
        policies[numberOfPolicies] = Policy({
            policyUniqueIdentifier: numberOfPolicies,
            policyValue: _cryptoValueToBeInsured,
            monthlyInstallment: installment,
            numberOfInstallments: 0,
            valueOfInstallments: 0,
            companyFundsInvestedIn: _holdingCompanyId,
            owner: msg.sender
        });

        numberOfPoliciesPerUser[msg.sender] += 1;
        numberOfPolicies++;

    }

    function calculatePolicyInstallments(uint256 _value, uint256 _holdingCompanyId) public returns (uint256) {
        
        //If the user would pay the total value in 15 years of installments, what would they pay per month
        uint256 expected15YearInstallment = _value / 180;
        uint256 safetyAdjustment = 100 - holdingCompanies[_holdingCompanyId].safetyRating;
        uint256 policyInstallment = expected15YearInstallment + ((expected15YearInstallment * safetyAdjustment) / 100);

        return policyInstallment;
    }

    function getNumberOfPolicies(uint256 _policyId) public view returns (uint256) {
        return numberOfPolicies;
    }
    
}
