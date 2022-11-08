// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";
import "./CHToken.sol";

import {console} from "forge-std/console.sol";

contract FundManager {
    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------- STRUCTS ----------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------ STATE VARIABLES -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    uint256 public numberOfLiquidityProviders;
    uint256 public totalLiquidityProvided;
    uint256 public feePercentage;
    uint256 public totalFees;
    address public owner;
    IERC20 usdc;
    CHToken token;
    IInsurance insurance;

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------ DATA STRUCTURES -----------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    mapping(uint256 => LiquidityProvider) public providers;
    mapping(address => uint256) public providerToId;

    //----------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------- EVENTS ---------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    event UpdatedFeePercentage(uint256 newFeePercentage);
    event TransferredOwnership(address newOwner);
    event ClaimPaid(address reciever, uint256 amountPaid);

    //----------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------- CONSTRUCTOR ------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Constructor
    @param _usdcAddress Address of the USDC token.
    @param _insuranceAddress Address of the Insurance.sol contract.
    @param _chTokenAddress Address of the Crypto Hack Token.
     */
    constructor(address _usdcAddress, address _insuranceAddress, address _chTokenAddress) {
        usdc = IERC20(_usdcAddress);
        token = CHToken(_chTokenAddress);
        insurance = IInsurance(_insuranceAddress);
        owner = msg.sender;
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------- STATE MODIFYING FUNCTIONS -----------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Creating a new liquidity provider object to store their information.
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
    @notice Adding liquidity to the contract which will hold the USDC.
    @dev User must approve contract before calling function.
    @param _providerId ID of the user who is depositing liquidity.
    @param _amount The amount of USDC to be sent to the contract.
     */
    function addLiquidity(uint256 _providerId, uint256 _amount) public {
        require(
            _providerId <= numberOfLiquidityProviders,
            "Invalid provider ID"
        );
        require(providerToId[msg.sender] == _providerId, "Not correct caller");

        providers[_providerId].valueOfLiquidity += _amount;
        totalLiquidityProvided += _amount;
        usdc.transferFrom(msg.sender, address(this), _amount);
    }

    /**
    @notice User paying one of their installments to the contract in USDC.
    @dev User must approve contract before calling function.
    @param _policyId ID of the policy the user is paying an installment for.
    @param _amount The amount of USDC to be sent to the contract.
     */
    function payPolicyInstallment(uint256 _policyId, uint256 _amount) public {
        require(
            _policyId < insurance.getNumberOfPolicies(),
            "Invalid policy ID"
        );
        require(
            insurance.getPolicyOwner(_policyId) == msg.sender,
            "Not policy owner"
        );

        usdc.transferFrom(msg.sender, address(this), _amount);
        insurance.addPolicyPayment(_amount, _policyId);

        uint256 totalLiquidity = totalLiquidityProvided;
        uint256 numberOfProviders = numberOfLiquidityProviders;
        uint256 feeAmount = (_amount * feePercentage) / 100;

        totalFees += feeAmount;

        uint256 distritutionAmount = _amount - feeAmount;

        for (uint256 x = 0; x < numberOfProviders; x++) {
            LiquidityProvider memory provider = providers[x];
            uint256 portion = (provider.valueOfLiquidity * 100) /
                totalLiquidity;
            uint256 valueToSend = (portion * distritutionAmount) / 100;
            usdc.transfer(provider.wallet, valueToSend);
        }
    }

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
    @notice Owner can distribute the fees collected to the CH Token holders.
     */
    function distributePlatformFees() public onlyOwner {
        uint256 totalCHTokenSupply = token.totalSupply();

        for(uint256 x = 0; x < token.numberOfHolders(); x++){
        }
    }

    /**
    @notice Distributing the funds when a hack has been approved
    @param _to Address of the owner of the policy being paid out.
    @param _amount Amount to pay out.
     */
    function distributeHackFunds(address _to, uint256 _amount) external {
        require(msg.sender == address(insurance), "Incorrect caller");
        console.log(1);
        usdc.transfer(_to, _amount);

        emit ClaimPaid(_to, _amount);
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------- SETTER FUNCTIONS ---------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    /**
    @notice Changing the fee percentage collected on installments.
    @param _newFeePercentage New percentage between 0 - 100 for fees.
     */
    function setFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Invalid percentage");
        feePercentage = _newFeePercentage;

        emit UpdatedFeePercentage(_newFeePercentage);
    }

    //----------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------- MODIFIERS ------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner function");
        _;
    }
}
