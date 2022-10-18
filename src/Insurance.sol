// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import {console} from "forge-std/console.sol";
import "./Interfaces/IFundManager.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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

    struct LiquidityProvider {
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    uint256 public numberOfPolicies = 0;
    uint256 public numberOfHoldingCompanies = 0;
    uint256 public numberOfLiquidityProviders = 0;

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => HoldingCompany) public holdingCompanies;
    mapping(uint256 => LiquidityProvider) public providers;

    mapping(address => uint256) public numberOfPoliciesPerUser;

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
    }

    function createNewLiquidityProvider(uint256 _liquidityValue, address _managerAddress) public {
        providers[numberOfLiquidityProviders] = LiquidityProvider({
            wallet: msg.sender,
            valueOfLiquidity: _liquidityValue,
            policyProfits: 0
        });

        addLiquidity(_liquidityValue, _managerAddress);

        numberOfLiquidityProviders++;
    }

    function addPolicyPayment(uint256 _amount, uint256 _policyId) public {
        require(_amount == policies[_policyId].monthlyInstallment, "Incorrect payment amount");

        policies[_policyId].numberOfInstallments++;
        policies[_policyId].valueOfInstallments += _amount;
    }

    function addLiquidity(uint256 _amount, address _fundManager) public {
        
        usdc.transferFrom(msg.sender, _fundManager, _amount);

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
