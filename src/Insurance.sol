// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import {console} from "forge-std/console.sol";
import "./Interfaces/IFundManager.sol";
import "./Interfaces/IInsurance.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract Insurance is IInsurance {
    

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
    mapping(uint256 => IInsurance.Hack) public hacks;
    mapping(address => uint256) public numberOfPoliciesPerUser;

    //----------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------- EVENTS ----------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    event TransferredOwnership(address newOwner);
    event ApproveHack(uint256 hackId, uint256 amountPaidOut);
    event RejectHack(uint256 hackId);
    event HackAdded(uint256 hackiD, uint256 policyId);

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------- CONSTRUCTOR -------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Constructor.
    @param _usdcAddress Address of the USDC token.
     */
    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
        owner = msg.sender;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------- STATE MODIFYING FUNCTIONS ----------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Adding information about a policy installment to the relevant policy.
    @param _amount The amount of USDC that was paid.
    @param _policyId The id of the policy the installment was paid for.
     */
    function addPolicyPayment(uint256 _amount, uint256 _policyId) public {
        require(
            _amount == policies[_policyId].monthlyInstallment,
            "Incorrect payment amount"
        );
        require(policies[_policyId].closed == false, "Policy has been closed");

        policies[_policyId].numberOfInstallments++;
        policies[_policyId].valueOfInstallments += _amount;
    }

    /**
    @notice Creating a holding company (company a user can have funds invested in) object to hold information regarding companies.
    @param _safetyRating The safety rating of the company out of 100.
    @dev The sefty rating helps calculate the installment value for a policy.
     */
    function createHoldingCompany(uint256 _safetyRating) public onlyOwner {
        require(_safetyRating <= 100, "Invalid rating");

        holdingCompanies[numberOfHoldingCompanies] = HoldingCompany({
            id: numberOfHoldingCompanies,
            safetyRating: _safetyRating
        });

        numberOfHoldingCompanies++;
    }

    /**
    @notice Creating a policy object to hold information regarding policies.
    @param _cryptoValueToBeInsured The amount of crypto in USDC to be insured.
    @param _holdingCompanyId The ID of the company the crypto is being stored in.
     */
    function createPolicy(
        uint256 _cryptoValueToBeInsured,
        uint256 _holdingCompanyId
    ) public {
        uint256 installment = calculatePolicyInstallments(
            _cryptoValueToBeInsured,
            _holdingCompanyId
        );

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

    /**
    @notice Calculating how much a user should pay per installment.
    @param _value The amount of crypto the polciy is insuring.
    @param _holdingCompanyId The ID of the company the crypto is being stored in.
     */
    function calculatePolicyInstallments(
        uint256 _value,
        uint256 _holdingCompanyId
    ) public returns (uint256) {
        uint256 expected15YearInstallment = _value / 180;
        uint256 safetyAdjustment = 100 -
            holdingCompanies[_holdingCompanyId].safetyRating;
        uint256 policyInstallment = expected15YearInstallment +
            ((expected15YearInstallment * safetyAdjustment) / 100);

        return policyInstallment;
    }

    /**
    @notice Adding information about a hack to the relevant data structure.
    @param _policyId The ID of the policy the hack refers to.
     */
    function addHack(
        uint256 _policyId
    ) public {
        require(policies[_policyId].closed == false, "Policy has been closed");

        require(
            _policyId < numberOfPolicies,
            "Invalid policy ID"
        );
        require(
            policies[_policyId].owner == msg.sender,
            "Not correct caller"
        );

        hacks[numberOfHacks] = IInsurance.Hack({
            hackId: numberOfHacks,
            policyId: _policyId,
            amountPaidOut: 0,
            accepted: false,
            timeOfPayout: 0
        });

        policies[_policyId].closed = true;
        numberOfHacks++;

        emit HackAdded(numberOfHacks-1, _policyId);
    }

    
    /**
    @notice Rejecting a hack, only done by owner
    @param _hackId Policy the hack is being approved for
     */
    function rejectHack(uint256 _hackId) external onlyOwner {
        
        IInsurance.Hack storage tempHack = hacks[_hackId];
        uint256 policyId = tempHack.policyId;

        require(
            policyId < numberOfPolicies,
            "Invalid policy ID"
        );

        tempHack.accepted = false;
        tempHack.timeOfPayout = 0;
        tempHack.amountPaidOut = 0;

        emit RejectHack(_hackId);
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------- SETTER FUNCTIONS -------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Owner transferring ownership of contract to another address.
    @param _newOwner Address of the new owner of the contract.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Cannot be zero address");
        owner = _newOwner;

        emit TransferredOwnership(_newOwner);
    }

    /**
    @notice Owner transferring ownership of contract to another address.
    @param _hackId The id of the hack being updated.
    @param _valueOfPolicy The value of the payout.
     */
    function updateHackAfterApproval(uint256 _hackId, uint256 _valueOfPolicy) external {
        hacks[_hackId].accepted = true;
        hacks[_hackId].timeOfPayout = block.timestamp;
        hacks[_hackId].amountPaidOut = _valueOfPolicy;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------MODIFIERS-------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner function");
        _;
    }
}
