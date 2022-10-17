// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";

import {console} from "forge-std/console.sol";

contract InsuranceTests is Test {

    Insurance insuranceInstance;
   
    function setUp() public {

        insuranceInstance = new Insurance();
       
    }

    function testCreateHoldingCompany() public {

        insuranceInstance.createHoldingCompany(50);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 1);

        insuranceInstance.createHoldingCompany(80);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 2);
      
    }

    function testCalculatePolicyInstallments() public {
        insuranceInstance.createHoldingCompany(50);
        uint256 val = insuranceInstance.calculatePolicyInstallments(250000, 0);
        assertEq(val, 6249);

        insuranceInstance.createHoldingCompany(95);
        uint256 val2 = insuranceInstance.calculatePolicyInstallments(500000, 1);
        assertEq(val2, 8749);
    }
}
