// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";

import {console} from "forge-std/console.sol";

contract FundManager {

    IERC20 usdc;
    IInsurance insurance;

    struct LiquidityProvider {
        uint256 id;
        address wallet;
        uint256 valueOfLiquidity;
        uint256 policyProfits;
    }

    uint256 public numberOfLiquidityProviders;
    uint256 public totalLiquidityProvided;

    mapping(uint256 => LiquidityProvider) public providers;
    mapping(address => uint256) public providerToId;

    constructor(address _usdcAddress, address _insuranceAddress) {
        usdc = IERC20(_usdcAddress);
        insurance = IInsurance(_insuranceAddress);
    }   

    function createNewLiquidityProvider(address _managerAddress) public {
        
        //addLiquidity(msg.sender, _liquidityValue, _managerAddress);

        providers[numberOfLiquidityProviders] = LiquidityProvider({
            id: numberOfLiquidityProviders,
            wallet: msg.sender,
            valueOfLiquidity: 0,
            policyProfits: 0
        });

        providerToId[msg.sender] = numberOfLiquidityProviders;
        numberOfLiquidityProviders++;
    }

     function addLiquidity(uint256 _providerId, uint256 _amount, address _fundManager) public {

        require(_providerId <= numberOfLiquidityProviders, "Invalid provider ID");
        require(providerToId[msg.sender] == _providerId, "Not correct caller");
        
        providers[_providerId].valueOfLiquidity += _amount;
        totalLiquidityProvided += _amount;

        usdc.transferFrom(msg.sender, _fundManager, _amount);

    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidityProvided;
    }

    function payPolicyInstallment(uint256 _policyId, uint256 _amount) public {

        require(_policyId <= insurance.getNumberOfPolicies(), "Invalid policy ID");

        usdc.transferFrom(msg.sender, address(this), _amount);
        insurance.addPolicyPayment(_amount, _policyId);

        //Transfer amount to the different wallets
        uint256 totalLiquidity = totalLiquidityProvided;
        uint256 numberOfProviders = numberOfLiquidityProviders;

        for(uint256 x = 0; x < numberOfProviders; x++){

            LiquidityProvider memory provider = providers[x];   
            uint256 portion = (provider.valueOfLiquidity*100) / totalLiquidity;

            uint256 valueToSend = portion * _amount / 100;

            usdc.transfer(provider.wallet, valueToSend);

        }
    } 

    //Maybe have a createHack and then only owner can approve a hack
    function claimHack(uint256 _policyId) public {
        require(_policyId < insurance.getNumberOfPolicies(), "Invalid policy ID");
        require(insurance.getPolicyOwner(_policyId) == msg.sender, "Not correct caller");

        uint256 policyVal = insurance.getPolicyValue(_policyId);

        insurance.addHack(_policyId, policyVal, true);

        //usdc.transfer(msg.sender, policyVal);
    }
    
}
