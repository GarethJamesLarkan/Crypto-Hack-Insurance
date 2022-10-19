// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";

import {console} from "forge-std/console.sol";


contract FundManager {

    IERC20 usdc;
    IInsurance insurance;

    uint256 public totalLiquidityProvided;

    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    uint256 public numberOfLiquidityProviders;
    
    mapping(uint256 => LiquidityProvider) public providers;
    mapping(address => uint256) public providerToId;

    constructor(address _usdcAddress, address _insuranceAddress) {
        usdc = IERC20(_usdcAddress);
        insurance = IInsurance(_insuranceAddress);
    }   

    function createNewLiquidityProvider(uint256 _liquidityValue, address _managerAddress) public {
        
        addLiquidity(msg.sender, _liquidityValue, _managerAddress);

        providers[numberOfLiquidityProviders] = LiquidityProvider({
            id: numberOfLiquidityProviders,
            wallet: msg.sender,
            valueOfLiquidity: 0,
            policyProfits: 0
        });

        providerToId[msg.sender] = numberOfLiquidityProviders;
        numberOfLiquidityProviders++;
    }

     function addLiquidity(address _sender, uint256 _amount, address _fundManager) public {
        
        providers[providerToId[_sender]].valueOfLiquidity += _amount;
        totalLiquidityProvided += _amount;

        usdc.transferFrom(_sender, _fundManager, _amount);

    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidityProvided;
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
            uint256 portion = (provider.valueOfLiquidity*100) / (totalLiquidity);
            console.log(portion);
            console.log(provider.valueOfLiquidity);

            uint256 valueToSend = portion * _amount / 100;
            console.log(valueToSend);

            usdc.transfer(provider.wallet, valueToSend);

        }
    } 
    
}
