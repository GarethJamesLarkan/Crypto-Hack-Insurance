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

    function testCreatePolicy() public {
        
    }
}
