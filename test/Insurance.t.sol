// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/MockUSDC.sol";
import "../src/CHToken.sol";

import {console} from "forge-std/console.sol";

contract InsuranceTests is Test {
    Insurance insuranceInstance;
    FundManager managerInstance;

    MockUSDC token;
    CHToken chToken;


    address zero = 0x0000000000000000000000000000000000000000;
    address owner = vm.addr(3);
    address alice = vm.addr(4);
    address bob = vm.addr(5);
    address liquidityProvider1 = vm.addr(6);
    address liquidityProvider2 = vm.addr(7);

    function setUp() public {
        vm.startPrank(owner);
        token = new MockUSDC();
        chToken = new CHToken(address(token));
        insuranceInstance = new Insurance(address(token));
        managerInstance = new FundManager(
            address(token),
            address(insuranceInstance),
            address(chToken)
        );
        vm.stopPrank();
    }

    function testCreateHoldingCompany() public {
        vm.startPrank(owner);
        insuranceInstance.createHoldingCompany(50);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 1);

        (uint256 id, uint256 safetyRating) = insuranceInstance.holdingCompanies(
            0
        );
        assertEq(id, 0);
        assertEq(safetyRating, 50);

        insuranceInstance.createHoldingCompany(80);
        assertEq(insuranceInstance.numberOfHoldingCompanies(), 2);

        (id, safetyRating) = insuranceInstance.holdingCompanies(1);
        assertEq(id, 1);
        assertEq(safetyRating, 80);
        vm.stopPrank();
    }

    function testCalculatePolicyInstallments() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);
        uint256 val = insuranceInstance.calculatePolicyInstallments(250000, 0);
        assertEq(val, 2082);

        vm.prank(owner);
        insuranceInstance.createHoldingCompany(95);
        uint256 val2 = insuranceInstance.calculatePolicyInstallments(500000, 1);
        assertEq(val2, 2915);
    }

    function testAddHack() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);

        insuranceInstance.addHack(0);

        (
            uint256 hackId,
            uint256 policyId,
            uint256 amountPaidOut,
            bool accepted,
        ) = insuranceInstance.hacks(0);

        assertEq(hackId, 0);
        assertEq(policyId, 0);
        assertEq(amountPaidOut, 0);
        assertEq(accepted, false);

        (, , , , , , bool closed, ) = insuranceInstance.policies(0);
        assertEq(closed, true);
    }

    function testRejectHack() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.stopPrank();

        vm.prank(owner);
        insuranceInstance.rejectHack(0);
        
        (
            uint256 hackId,
            uint256 policyId,
            uint256 amountPaidOut,
            bool accepted,
        ) = insuranceInstance.hacks(0);
        
        assertEq(hackId, 0);
        assertEq(policyId, 0);
        assertEq(amountPaidOut, 0);
        assertEq(accepted, false);
    }

    function testApproveHack() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);

        insuranceInstance.addHack(0);

        (
            uint256 hackId,
            uint256 policyId,
            uint256 amountPaidOut,
            bool accepted,
        ) = insuranceInstance.hacks(0);

        vm.stopPrank();
        
        vm.prank(owner);
        managerInstance.approveHack(0);

        assertEq(token.balanceOf(alice), 310000);
        assertEq(token.balanceOf(address(managerInstance)), 10000);
        
        (
            uint256 hackIdAfter,
            uint256 policyIdAfter,
            uint256 amountPaidOutAfter,
            bool acceptedAfter,
        ) = insuranceInstance.hacks(0);

        assertEq(hackIdAfter, 0);
        assertEq(policyIdAfter, 0);
        assertEq(amountPaidOutAfter, 10000);
        assertEq(acceptedAfter, true);

        (, , , , , , bool closed, ) = insuranceInstance.policies(0);
        assertEq(closed, true);
    }

    function testAddHackFailsWhenIncorrectPolicyID() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.expectRevert("Invalid policy ID");
        insuranceInstance.addHack(1);
    }

    function testAddHackFailsWhenPolicyIsClosed() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

        //Alice creating a policy
        vm.startPrank(alice);
        token.approve(address(managerInstance), 4000000);
        insuranceInstance.createPolicy(10000, 0);
        assertEq(token.balanceOf(alice), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);

        insuranceInstance.addHack(0);

        vm.expectRevert("Policy has been closed");
        insuranceInstance.addHack(0);
    }
    

    function testAddHackFailsWhenIncorrectCaller() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.startPrank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);
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
        insuranceInstance.addHack(0);
    }

    function testCreatePolicy() public {
        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        vm.startPrank(alice);
        insuranceInstance.createPolicy(250000, 0);

        (
            uint256 id,
            uint256 value,
            uint256 installment,
            uint256 numOfInstallments,
            uint256 valueOfInstallments,
            uint256 holdingcompany,
            ,
            address owner
        ) = insuranceInstance.policies(0);

        assertEq(insuranceInstance.numberOfPolicies(), 1);
        assertEq(value, 250000);
        assertEq(installment, 2082);
        assertEq(numOfInstallments, 0);
        assertEq(numOfInstallments, 0);
        assertEq(holdingcompany, 0);
        assertEq(owner, address(alice));
    }
}
