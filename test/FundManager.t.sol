// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/MockUSDC.sol";

import {console} from "forge-std/console.sol";

contract FundManagerTests is Test {

    FundManager managerInstance;
    Insurance insuranceInstance;
    MockUSDC token;
   
    address alice = vm.addr(3);
    address bob = vm.addr(4);
    address liquidityProvider1 = vm.addr(5);
    address liquidityProvider2 = vm.addr(6);


    function setUp() public {

        token = new MockUSDC();
        insuranceInstance = new Insurance(address(token));
        managerInstance = new FundManager(address(token), address(insuranceInstance));
    }

    function testSetFeePercentage() public {
        managerInstance.setFeePercentage(20);
        assertEq(managerInstance.feePercentage(), 20);
    }

    function testSetFeePercentageFailsWhenPercentageBiggerThan100() public {
        vm.expectRevert("Invalid percentage");
        managerInstance.setFeePercentage(101);
    }

    function testAddInstallment() public {

        vm.startPrank(alice);

        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);    

        token.approve(address(managerInstance), 400000);

        managerInstance.createNewLiquidityProvider(address(managerInstance));
        
        assertEq(token.balanceOf(alice), aliceBalanceBefore);

        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        //First payment and checks
        managerInstance.payPolicyInstallment(0, 2082);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        (uint256 id, uint256 value, uint256 installment, uint256 numOfInstallments, uint256 valueOfInstallments, uint256 holdingcompany,, address owner) = insuranceInstance.policies(0); 

        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 1);
        assertEq(valueOfInstallments, 2082);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));

        //Second payment and checks
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 20000);

        (, uint256 value2, uint256 installment2, uint256 numOfInstallments2, uint256 valueOfInstallments2, uint256 holdingcompany2,, address owner2) = insuranceInstance.policies(0); 

        assertEq(value2, 250000);
        assertEq(installment2, 2082);
        assertEq(numOfInstallments2, 2);
        assertEq(valueOfInstallments2, 4164);
        assertEq(holdingcompany2, 0);
        assertEq(owner2, address(alice));

        vm.stopPrank();
        vm.startPrank(bob);

        token.mint(bob, 300000);
        token.approve(address(managerInstance), 400000);

        insuranceInstance.createPolicy(250000, 0);  
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 282082);
        assertEq(token.balanceOf(bob), 300000-2082);

    }

    function testPayInstallmentFailsWhenPolicyDoesNotExist() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        insuranceInstance.createHoldingCompany(50);
        insuranceInstance.createPolicy(250000, 0);    

        token.approve(address(managerInstance), 400000);

        //First payment and checks
        vm.expectRevert("Incorrect payment amount");
        managerInstance.payPolicyInstallment(1, 2082);
        
    }

    function testAddInstallmentWith2LiquidityProviders() public {

        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.prank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider(address(managerInstance));

        //Liquidity provider 2 adding themself to the mapping
        vm.prank(liquidityProvider2);
        managerInstance.createNewLiquidityProvider(address(managerInstance));

        assertEq(managerInstance.numberOfLiquidityProviders(), 2);

        //Making sure the LP have been correctly instantiated
        (uint256 id, address wallet, uint256 valueOfLiquidity, uint256 policyProfits) = managerInstance.providers(0); 
        assertEq(id, 0);
        assertEq(wallet, liquidityProvider1);
        assertEq(valueOfLiquidity, 0);
        assertEq(policyProfits, 0);

        (uint256 id2, address wallet2, uint256 valueOfLiquidity2, uint256 policyProfits2) = managerInstance.providers(1); 
        assertEq(id2, 1);
        assertEq(wallet2, liquidityProvider2);
        assertEq(valueOfLiquidity2, 0);
        assertEq(policyProfits2, 0);

        vm.startPrank(liquidityProvider1);
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(0, 20000, address(managerInstance));

        assertEq(token.balanceOf(liquidityProvider1), 280000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.stopPrank();

        vm.startPrank(liquidityProvider2);
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000, address(managerInstance));

        assertEq(token.balanceOf(liquidityProvider2), 280000);
        assertEq(token.balanceOf(address(managerInstance)), 40000);
        assertEq(token.balanceOf(liquidityProvider1), 280000);
        vm.stopPrank();

        vm.startPrank(alice);
        insuranceInstance.createPolicy(250000, 0);
        
        (uint256 aliceId, uint256 aliceValue, uint256 aliceInstallment, uint256 aliceNumOfInstallments, uint256 aliceValueOfInstallments, uint256 aliceHoldingcompany,, address aliceOwner) = insuranceInstance.policies(0); 
        assertEq(aliceId, 0);
        assertEq(aliceValue, 250000);
        assertEq(aliceInstallment, 2082);
        assertEq(aliceNumOfInstallments, 0);
        assertEq(aliceValueOfInstallments, 0);
        assertEq(aliceHoldingcompany, 0);
        assertEq(aliceOwner, address(alice));
        vm.stopPrank();
        
        vm.startPrank(bob);
        insuranceInstance.createPolicy(250000, 0); 

        (uint256 bobId, uint256 bobValue, uint256 bobInstallment, uint256 bobNumOfInstallments, uint256 bobValueOfInstallments, uint256 bobHoldingcompany,, address bobOwner) = insuranceInstance.policies(1); 
        assertEq(bobId, 1);
        assertEq(bobValue, 250000);
        assertEq(bobInstallment, 2082);
        assertEq(bobNumOfInstallments, 0);
        assertEq(bobValueOfInstallments, 0);
        assertEq(bobHoldingcompany, 0);
        assertEq(bobOwner, address(bob)); 
        vm.stopPrank();
        
        assertEq(token.balanceOf(liquidityProvider1), 280000);
        assertEq(token.balanceOf(liquidityProvider2), 280000);
        assertEq(token.balanceOf(address(managerInstance)), 40000);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(bob), 300000);
        
        vm.prank(alice);
        token.approve(address(managerInstance), 400000);

        vm.prank(bob);
        token.approve(address(managerInstance), 400000);

        vm.startPrank(alice);
        managerInstance.payPolicyInstallment(0, 2082);

        assertEq(token.balanceOf(liquidityProvider1), 281041);
        assertEq(token.balanceOf(liquidityProvider2), 281041);
        assertEq(token.balanceOf(alice), 297918);
        assertEq(token.balanceOf(bob), 300000);

        (uint256 aliceId2, uint256 aliceValue2, uint256 aliceInstallment2, uint256 aliceNumOfInstallments2, uint256 aliceValueOfInstallments2,,,) = insuranceInstance.policies(0); 
        assertEq(aliceId2, 0);
        assertEq(aliceValue2, 250000);
        assertEq(aliceInstallment2, 2082);
        assertEq(aliceNumOfInstallments2, 1);
        assertEq(aliceValueOfInstallments2, 2082);
        vm.stopPrank();

        vm.startPrank(bob);
        managerInstance.payPolicyInstallment(1, 2082);

        assertEq(token.balanceOf(liquidityProvider1), 282082);
        assertEq(token.balanceOf(liquidityProvider2), 282082);
        assertEq(token.balanceOf(alice), 297918);
        assertEq(token.balanceOf(bob), 297918);

        (, uint256 bobValue2, uint256 bobInstallment2, uint256 bobNumOfInstallments2, uint256 bobValueOfInstallments2,,,) = insuranceInstance.policies(1); 
        assertEq(bobValue2, 250000);
        assertEq(bobInstallment2, 2082);
        assertEq(bobNumOfInstallments2, 1);
        assertEq(bobValueOfInstallments2, 2082);
        vm.stopPrank();
    }

    function testCreatingLiquidityProvider() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider(address(managerInstance));
        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (,, uint256 valueOfLiquidity,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity, 20000);

    }

    function testAddLiquidity() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider(address(managerInstance));
        managerInstance.addLiquidity(0, 20000, address(managerInstance));

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (,, uint256 valueOfLiquidity,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity, 20000);

        managerInstance.addLiquidity(0, 50000, address(managerInstance));

        assertEq(token.balanceOf(address(managerInstance)), 70000);
        assertEq(token.balanceOf(alice), 230000);

        (,, uint256 valueOfLiquidity2,) = managerInstance.providers(managerInstance.providerToId(alice));

        assertEq(valueOfLiquidity2, 70000);
    }

    function testAddHack() public {
        
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider(address(managerInstance));
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        
        managerInstance.claimHack(0);
        assertEq(token.balanceOf(alice), 310000);
        assertEq(token.balanceOf(address(managerInstance)), 10000);

        (uint256 hackId, uint256 policyId, uint256 amountPaidOut, bool accepted,) = insuranceInstance.hacks(0);
        assertEq(hackId, 0);
        assertEq(policyId, 0);
        assertEq(amountPaidOut, 10000);
        assertEq(accepted, true);

        (,,,,,,bool closed,) = insuranceInstance.policies(0);
        assertEq(closed, true);

    }

    function testClaimHackFailsWhenIncorrectCaller() public {
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider(address(managerInstance));
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Not correct caller");
        managerInstance.claimHack(0);

    }

    function testClaimHackFailsWhenIncorrectPolicyID() public {
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider(address(managerInstance));
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.expectRevert("Invalid policy ID");
        managerInstance.claimHack(1);

    }

    function testClaimHackFailsWhenPolicyIsClosed() public {
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider(address(managerInstance));
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(0, 20000, address(managerInstance));
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);

        managerInstance.claimHack(0);
        
        vm.expectRevert("Policy has been closed");
        managerInstance.claimHack(0);
    }
}
