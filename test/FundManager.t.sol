// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/CHToken.sol";

import {console} from "forge-std/console.sol";

contract FundManagerTests is Test {

    FundManager managerInstance;
    Insurance insuranceInstance;
    CHToken token;
   
    address alice = vm.addr(3);

    function setUp() public {

        token = new CHToken();
        insuranceInstance = new Insurance();
        managerInstance = new FundManager(address(token), address(insuranceInstance));
    }

    function testAddInstallment() public {

        vm.startPrank(alice);

        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);      

        token.approve(address(managerInstance), 400000);

        //First payment and checks
        managerInstance.payPolicyInstallment(0, 2082);
        
        assertEq(token.balanceOf(address(managerInstance)), 2082);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 2082);

        (uint256 id, uint256 value, uint256 installment, uint256 numOfInstallments, uint256 valueOfInstallments, uint256 holdingcompany, address owner) = insuranceInstance.policies(0); 

        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 1);
        assertEq(valueOfInstallments, 2082);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));

        //Second payment and checks
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(address(managerInstance)), 4164);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 4164);

        (, uint256 value2, uint256 installment2, uint256 numOfInstallments2, uint256 valueOfInstallments2, uint256 holdingcompany2, address owner2) = insuranceInstance.policies(0); 

        assertEq(value2, 250000);
        assertEq(installment2, 2082);
        assertEq(numOfInstallments2, 2);
        assertEq(valueOfInstallments2, 4164);
        assertEq(holdingcompany2, 0);
        assertEq(owner2, address(alice));

    }
}
