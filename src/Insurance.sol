// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import {console} from "forge-std/console.sol";
import "./Interfaces/IFundManager.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract Insurance {

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

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------ STATE VARIABLES -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    uint256 public numberOfPolicies;
    uint256 public numberOfHoldingCompanies;
    uint256 public numberOfHacks;
    address public owner;
    IFundManager manager;
    IERC20 usdc;

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------ DATA STRUCTURES -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => HoldingCompany) public holdingCompanies;
    mapping(uint256 => Hack) public hacks;
    mapping(address => uint256) public numberOfPoliciesPerUser;


    //----------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------- EVENTS ----------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    event TransferredOwnership(address newOwner);

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------- CONSTRUCTOR -------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
        owner = msg.sender;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------- STATE MODIFYING FUNCTIONS ----------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    function addPolicyPayment(uint256 _amount, uint256 _policyId) public {
        require(_amount == policies[_policyId].monthlyInstallment, "Incorrect payment amount");
        require(policies[_policyId].closed == false, "Policy has been closed");

        policies[_policyId].numberOfInstallments++;
        policies[_policyId].valueOfInstallments += _amount;

    }

    function createHoldingCompany(uint256 _safetyRating) public onlyOwner {
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
            closed: false,
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

    function addHack(uint256 _policyId, uint256 _amountPaid, bool _accepted) public {

        require(policies[_policyId].closed == false, "Policy has been closed");

        hacks[numberOfHacks] = Hack({
            hackId: numberOfHacks,
            policyId: _policyId,
            amountPaidOut: _amountPaid,
            accepted: _accepted,
            timeOfPayout: block.timestamp
        });

        policies[_policyId].closed = true;

        numberOfHacks++;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------- SETTER FUNCTIONS -------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Cannot be zero address");
        owner = _newOwner;

        emit TransferredOwnership(_newOwner);
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------- GETTERS -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    function getNumberOfPolicies() public view returns (uint256) {
        return numberOfPolicies;
    }

    function getPolicyValue(uint256 _policyId) public view returns (uint256) {
        return policies[_policyId].policyValue;
    }

    function getPolicyOwner(uint256 _policyId) public view returns (address) {
        return policies[_policyId].owner;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------MODIFIERS-------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner function");
        _;
    }
    
}
