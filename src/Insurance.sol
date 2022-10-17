// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;

contract Insurance {

    enum HOLDING_COMPANIES {
        BINANCE,
        AAVE,
        COINBASE,
        KRAKEN,
        YEARN
    }

    struct Policy {
        uint256 policyUniqueIdentifier;
        uint256 policyValue;
        uint256 monthlyInstallment;
        uint256 numberOfInstallments;
        HOLDING_COMPANIES companyFundsInvestedIn;
        address owner;
    }

    uint256 public numberOfPolicies;

    mapping(uint256 => Policy) public policies;

    constructor() {

    }

    //_holdingCompany is the number between 0-4 which correlates to the enum
    function createPolicy(uint256 _cryptoValueToBeInsured, HOLDING_COMPANIES _holdingCompany) {
        
        uint256 installment = calculatePolicyInstallments();
        
        policies[numberOfPolicies] = ({
            policyUniqueIdentifier = numberOfPolicies,
            policyValue = _cryptoValueToBeInsured,
            monthlyInstallment = installment,
            numberOfInstallments = 0,
            companyFundsInvestedIn = _holdingCompany,
            owner = msg.sender
        });

        numberOfPolicies++;

    }

    function calculatePolicyInstallments() internal {

    }
    
    
}
