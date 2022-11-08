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
    @notice User claiming they have been hacked and the contract paying them out.
    @dev FUTURE: Wont be able to just claim, will be onlyOwner and will be a review process.
    @param _policyId ID of the policy the user is claiming.
     */
    function registerHack(uint256 _policyId) public {
        require(
            _policyId < insurance.getNumberOfPolicies(),
            "Invalid policy ID"
        );
        require(
            insurance.getPolicyOwner(_policyId) == msg.sender,
            "Not correct caller"
        );

        uint256 policyVal = insurance.getPolicyValue(_policyId);
        addHack(_policyId, policyVal, false);
    }

    /**
    @notice Adding information about a hack to the relevant data structure.
    @param _policyId The ID of the policy the hack refers to.
    @param _amountPaid The value of the payout for the hack.
    @param _accepted If the hack was accepted or not, if rejected, value paid out will be 0.
     */
    function addHack(
        uint256 _policyId,
        uint256 _amountPaid,
        bool _accepted
    ) public {
        require(policies[_policyId].closed == false, "Policy has been closed");

        hacks[numberOfHacks] = Hack({
            hackId: numberOfHacks,
            policyId: _policyId,
            amountPaidOut: 0,
            accepted: _accepted,
            timeOfPayout: 0
        });

        policies[_policyId].closed = true;
        numberOfHacks++;
    }

    function approveHack(uint256 _policyId) external onlyOwner {
        require(
            _policyId < insurance.getNumberOfPolicies(),
            "Invalid policy ID"
        );

        uint256 valueOfPolicy = policies[_policyId].policyValue;

        hacks[_policyId].accepted = true;
        hacks[_policyId].timeOfPayout = block.timestamp;
        hacks[_policyId].amountPaidOut = valueOfPolicy;
    }

    function rejectHack(uint256 _policyId) external onlyOwner {
        require(
            _policyId < insurance.getNumberOfPolicies(),
            "Invalid policy ID"
        );

        hacks[_policyId].accepted = false;
        hacks[_policyId].timeOfPayout = 0;
        hacks[_policyId].amountPaidOut = 0;
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

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------- GETTERS -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Gets the number of policies currently in place.
    @return numberOfPolicies The current number of policies.
     */
    function getNumberOfPolicies() public view returns (uint256) {
        return numberOfPolicies;
    }

    /**
    @notice Returns the value of the specified policy.
    @param _policyId The id of the requested policy.
    @return policyValue The value of the policy for the given ID.
     */
    function getPolicyValue(uint256 _policyId) public view returns (uint256) {
        return policies[_policyId].policyValue;
    }

    /**
    @notice Returns the owner of the specified policy.
    @param _policyId The id of the requested policy.
    @return policyOwner The owner of the policy for the given ID.
     */
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
