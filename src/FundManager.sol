// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";

import {console} from "forge-std/console.sol";

contract FundManager {

    //Declare the instances of other contracts we will use
    IERC20 usdc;
    IInsurance insurance;

    //Store the owner of the contract
    address public owner;

    //Object to store liquidity provider information
    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    //State variables to store certain needed information
    uint256 public numberOfLiquidityProviders;
    uint256 public totalLiquidityProvided;
    uint256 public feePercentage;
    uint256 public totalFees;

    //Data structures for holding needed information
    mapping(uint256 => LiquidityProvider) public providers;
    mapping(address => uint256) public providerToId;

    //Events for emitting data to the front-end
    event UpdatedFeePercentage(uint256 newFeePercentage);
    event TransferredOwnership(address newOwner);

    /**
    @notice Constructor
    @param _usdcAddress address of the USDC token
    @param _insuranceAddress address of the Insurance.sol contract
     */
    constructor(address _usdcAddress, address _insuranceAddress) {
        usdc = IERC20(_usdcAddress);
        insurance = IInsurance(_insuranceAddress);
        owner = msg.sender;
    }   

    //----------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------STATE MODIFYING FUNCTIONS------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Creating a new liquidity provider object to store their information
     */
    function createNewLiquidityProvider() public {
        
        providers[numberOfLiquidityProviders] = LiquidityProvider({
            id: numberOfLiquidityProviders,
            wallet: msg.sender,
            valueOfLiquidity: 0,
            policyProfits: 0
        });

        providerToId[msg.sender] = numberOfLiquidityProviders;
        numberOfLiquidityProviders++;
    }

    /**
    @notice Adding liquidity to the contract which will hold the USDC
    @param _providerId Id of the user who is depositing liquidity
    @param _amount the amount of USDC to be sent to the contract
     */
    function addLiquidity(uint256 _providerId, uint256 _amount) public {

        require(_providerId <= numberOfLiquidityProviders, "Invalid provider ID");
        require(providerToId[msg.sender] == _providerId, "Not correct caller");
        
        providers[_providerId].valueOfLiquidity += _amount;
        totalLiquidityProvided += _amount;

        usdc.transferFrom(msg.sender, address(this), _amount);

    }

    /**
    @notice User paying one of their installments to the contract in USDC
    @param _policyId Id of the policy the user is paying an installment for
    @param _amount the amount of USDC to be sent to the contract
     */
    function payPolicyInstallment(uint256 _policyId, uint256 _amount) public {

        require(_policyId <= insurance.getNumberOfPolicies(), "Invalid policy ID");
        require(insurance.getPolicyOwner(_policyId) == msg.sender, "Not policy owner");

        usdc.transferFrom(msg.sender, address(this), _amount);
        insurance.addPolicyPayment(_amount, _policyId);

        uint256 totalLiquidity = totalLiquidityProvided;
        uint256 numberOfProviders = numberOfLiquidityProviders;

        uint256 feeAmount = _amount * feePercentage / 100;
        totalFees += feeAmount;

        uint256 distritutionAmount = _amount - feeAmount;

        for(uint256 x = 0; x < numberOfProviders; x++){

            LiquidityProvider memory provider = providers[x];   
            uint256 portion = (provider.valueOfLiquidity*100) / totalLiquidity;

            uint256 valueToSend = portion * distritutionAmount / 100;

            usdc.transfer(provider.wallet, valueToSend);

        }
    } 

    //Maybe have a createHack and then only owner can approve a hack
    function claimHack(uint256 _policyId) public {
        require(_policyId < insurance.getNumberOfPolicies(), "Invalid policy ID");
        require(insurance.getPolicyOwner(_policyId) == msg.sender, "Not correct caller");

        uint256 policyVal = insurance.getPolicyValue(_policyId);

        insurance.addHack(_policyId, policyVal, true);

        usdc.transfer(msg.sender, policyVal);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Cannot be zero address");
        owner = _newOwner;

        emit TransferredOwnership(_newOwner);
    }

    function distributePlatformFees() public onlyOwner {

    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------SETTER FUNCTIONS----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    function setFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Invalid percentage");
        feePercentage = _newFeePercentage;

        emit UpdatedFeePercentage(_newFeePercentage);
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------MODIFIERS-------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner function");
        _;
    }
    
}
