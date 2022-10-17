// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

contract Insurance {

    struct Policy {
        uint256 policyValue;
        uint256 monthlyInstallment;
        uint256 numberOfInstallments;
        address owner;
    }

    uint256 public numberOfPolicies;
    
}
