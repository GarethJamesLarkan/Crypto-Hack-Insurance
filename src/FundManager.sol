// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IInsurance.sol";

contract FundManager {

    IERC20 usdc;
    IInsurance insurance;

    constructor(address _usdcAddress, address _insuranceAddress) {
        usdc = IERC20(_usdcAddress);
        insurance = IInsurance(_insuranceAddress);
    }   

    function getAddress() public view returns (address) {
        return address(this);
    }

    function payPolicyInstallment(uint256 _policyId, uint256 _amount) public {

        require(_policyId <= insurance.getNumberOfPolicies(_policyId), "Invalid policy ID");

        usdc.transferFrom(msg.sender, address(this), _amount);
        insurance.addPolicyPayment(_amount, _policyId);
    } 
    
}
