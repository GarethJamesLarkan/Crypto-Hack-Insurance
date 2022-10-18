// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";

import {console} from "forge-std/console.sol";


contract FundManager {

    IERC20 usdc;
    IInsurance insurance;

    uint256 public totalLiquidityProvided = 0;

    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    uint256 public numberOfLiquidityProviders = 0;
    
    mapping(address => uint256) public liquidityProvidedPerUser;
    mapping(uint256 => LiquidityProvider) public providers;
    mapping(address => uint256) public providerToId;

    constructor(address _usdcAddress, address _insuranceAddress) {
        usdc = IERC20(_usdcAddress);
        insurance = IInsurance(_insuranceAddress);
    }   

    function createNewLiquidityProvider(uint256 _liquidityValue, address _managerAddress) public {
        
        addLiquidity(_liquidityValue, _managerAddress);

        providers[numberOfLiquidityProviders] = LiquidityProvider({
            id: numberOfLiquidityProviders,
            wallet: msg.sender,
            valueOfLiquidity: _liquidityValue,
            policyProfits: 0
        });

        providerToId[msg.sender] = numberOfLiquidityProviders;

        numberOfLiquidityProviders++;
    }

     function addLiquidity(uint256 _amount, address _fundManager) public {
        
        providers[providerToId[msg.sender]].valueOfLiquidity += _amount;
        totalLiquidityProvided += _amount;
        liquidityProvidedPerUser[msg.sender] += _amount;

        usdc.transferFrom(msg.sender, _fundManager, _amount);

    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function payPolicyInstallment(uint256 _policyId, uint256 _amount) public {

        require(_policyId <= insurance.getNumberOfPolicies(_policyId), "Invalid policy ID");

        usdc.transferFrom(msg.sender, address(this), _amount);
        insurance.addPolicyPayment(_amount, _policyId);

        //Transfer amount to the different wallets
        uint256 totalLiquidity = totalLiquidityProvided;
        uint256 numberOfProviders = numberOfLiquidityProviders;

        for(uint256 x = 0; x < numberOfProviders; x++){

            LiquidityProvider memory provider = providers[x];   
            uint256 portion = totalLiquidity / provider.valueOfLiquidity * 100;
            uint256 valueToSend = portion * _amount / 100;

            usdc.transfer(provider.wallet, valueToSend);

        }
    } 
    
}
