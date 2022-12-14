// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "forge-std/Test.sol";
import "../src/Insurance.sol";
import "../src/FundManager.sol";
import "../src/MockUSDC.sol";
import "../src/CHToken.sol";

import {console} from "forge-std/console.sol";

contract FundManagerTests is Test {
    FundManager managerInstance;
    Insurance insuranceInstance;
    MockUSDC token;
    CHToken chToken;

    address zero = 0x0000000000000000000000000000000000000000;
    address owner = vm.addr(3);
    address alice = vm.addr(4);
    address bob = vm.addr(5);
    address liquidityProvider1 = vm.addr(6);
    address liquidityProvider2 = vm.addr(7);

    event UpdatedFeePercentage(uint256 newFeePercentage);
    event TransferredOwnership(address newOwner);
    event ClaimPaid(address reciever, uint256 amountPaid);
    event ApproveHack(uint256 hackId, uint256 value);

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

    function testDeploymentWorks() public {
        assertEq(managerInstance.insuranceAddress(), address(insuranceInstance));
        assertEq(managerInstance.owner(), address(owner));
    }

    function testSetFeePercentage() public {
        vm.prank(owner);
        managerInstance.setFeePercentage(20);
        assertEq(managerInstance.feePercentage(), 20);
    }

    function testSetFeePercentageFailsWhenPercentageBiggerThan100() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid percentage");
        managerInstance.setFeePercentage(101);
    }

    function testSetFeePercentageFailsWhenNonOwnerCalls() public {
        vm.startPrank(alice);
        vm.expectRevert("Only owner function");
        managerInstance.setFeePercentage(70);
    }

    function testOwnershipTransfers() public {
        vm.prank(owner);
        managerInstance.transferOwnership(alice);
        assertEq(managerInstance.owner(), alice);
    }

    function testOwnershipTransfersFailsWhenTransferringToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Cannot be zero address");
        managerInstance.transferOwnership(zero);
    }

    function testOwnershipTransfersFailsWhenNonOwnerCalls() public {
        vm.prank(alice);
        vm.expectRevert("Only owner function");
        managerInstance.transferOwnership(alice);
    }

    function testPayInstallmentFailsWhenPolicyDoesNotExist() public {
        vm.startPrank(alice);
        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        vm.stopPrank();

        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        vm.startPrank(alice);
        insuranceInstance.createPolicy(250000, 0);

        token.approve(address(managerInstance), 400000);

        vm.expectRevert("Invalid policy ID");
        managerInstance.payPolicyInstallment(2);
    }

    function testPayInstallmentFailsWhenNonPolicyOwnerCalls() public {
        vm.startPrank(alice);
        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        vm.stopPrank();

        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        vm.prank(alice);
        insuranceInstance.createPolicy(250000, 0);

        vm.startPrank(bob);
        token.approve(address(managerInstance), 400000);

        vm.expectRevert("Not policy owner");
        managerInstance.payPolicyInstallment(0);
    }

    function testPayInstallmentFailsWhenPolicyHasBeenClosed() public {
        token.mint(address(managerInstance), 50000);

        vm.startPrank(alice);
        token.mint(alice, 300000);
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        vm.stopPrank();

        vm.prank(owner);
        insuranceInstance.createHoldingCompany(50);

        vm.startPrank(alice);
        insuranceInstance.createPolicy(10000, 0);
        token.approve(address(managerInstance), 400000);
        insuranceInstance.addHack(0);

        vm.expectRevert("Policy has been closed");
        managerInstance.payPolicyInstallment(0);
    }

    function testPayInstallmentWith2LiquidityProvidersAndTotalFeeUpdates()
        public
    {
        vm.startPrank(owner);
        insuranceInstance.createHoldingCompany(50);
        managerInstance.setFeePercentage(20);
        vm.stopPrank();

        //Give everyone funds
        token.mint(alice, 300000);
        token.mint(bob, 300000);
        token.mint(liquidityProvider1, 300000);
        token.mint(liquidityProvider2, 300000);

        //Liquidity provider 1 adding themself to the mapping
        vm.prank(liquidityProvider1);
        managerInstance.createNewLiquidityProvider();

        //Liquidity provider 2 adding themself to the mapping
        vm.prank(liquidityProvider2);
        managerInstance.createNewLiquidityProvider();

        assertEq(managerInstance.numberOfLiquidityProviders() - 1 , 2);

        //Making sure the LP have been correctly instantiated
        (
            uint256 id,
            address wallet,
            uint256 valueOfLiquidity,
            uint256 policyProfits
        ) = managerInstance.providers(1);
        assertEq(id, 1);
        assertEq(wallet, liquidityProvider1);
        assertEq(valueOfLiquidity, 0);
        assertEq(policyProfits, 0);

        (
            uint256 id2,
            address wallet2,
            uint256 valueOfLiquidity2,
            uint256 policyProfits2
        ) = managerInstance.providers(2);
        assertEq(id2, 2);
        assertEq(wallet2, liquidityProvider2);
        assertEq(valueOfLiquidity2, 0);
        assertEq(policyProfits2, 0);

        vm.startPrank(liquidityProvider1);
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(1, 20000);

        assertEq(token.balanceOf(liquidityProvider1), 280000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        vm.stopPrank();

        vm.startPrank(liquidityProvider2);
        token.approve(address(managerInstance), 4000000);
        managerInstance.addLiquidity(2, 20000);

        assertEq(token.balanceOf(liquidityProvider2), 280000);
        assertEq(token.balanceOf(address(managerInstance)), 40000);
        assertEq(token.balanceOf(liquidityProvider1), 280000);
        vm.stopPrank();

        vm.startPrank(alice);
        insuranceInstance.createPolicy(250000, 0);

        (
            uint256 aliceId,
            uint256 aliceValue,
            uint256 aliceInstallment,
            uint256 aliceNumOfInstallments,
            uint256 aliceValueOfInstallments,
            uint256 aliceHoldingcompany,
            ,
            address aliceOwner
        ) = insuranceInstance.policies(0);
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

        (
            uint256 bobId,
            uint256 bobValue,
            uint256 bobInstallment,
            uint256 bobNumOfInstallments,
            uint256 bobValueOfInstallments,
            uint256 bobHoldingcompany,
            ,
            address bobOwner
        ) = insuranceInstance.policies(1);
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
        managerInstance.payPolicyInstallment(0);

        assertEq(token.balanceOf(liquidityProvider1), 280833);
        assertEq(token.balanceOf(liquidityProvider2), 280833);
        assertEq(token.balanceOf(alice), 297918);
        assertEq(token.balanceOf(bob), 300000);
        assertEq(token.balanceOf(address(managerInstance)), 40416);

        assertEq(managerInstance.totalFees(), 416);

        (
            uint256 aliceId2,
            uint256 aliceValue2,
            uint256 aliceInstallment2,
            uint256 aliceNumOfInstallments2,
            uint256 aliceValueOfInstallments2,
            ,
            ,

        ) = insuranceInstance.policies(0);
        assertEq(aliceId2, 0);
        assertEq(aliceValue2, 250000);
        assertEq(aliceInstallment2, 2082);
        assertEq(aliceNumOfInstallments2, 1);
        assertEq(aliceValueOfInstallments2, 2082);
        vm.stopPrank();

        vm.startPrank(bob);
        managerInstance.payPolicyInstallment(1);

        assertEq(token.balanceOf(liquidityProvider1), 281666);
        assertEq(token.balanceOf(liquidityProvider2), 281666);
        assertEq(token.balanceOf(alice), 297918);
        assertEq(token.balanceOf(bob), 297918);
        assertEq(token.balanceOf(address(managerInstance)), 40832);

        assertEq(managerInstance.totalFees(), 832);

        (
            ,
            uint256 bobValue2,
            uint256 bobInstallment2,
            uint256 bobNumOfInstallments2,
            uint256 bobValueOfInstallments2,
            ,
            ,

        ) = insuranceInstance.policies(1);
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

        managerInstance.createNewLiquidityProvider();
        managerInstance.addLiquidity(1, 20000);
        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (, , uint256 valueOfLiquidity, ) = managerInstance.providers(1);

        assertEq(valueOfLiquidity, 20000);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider();
        managerInstance.addLiquidity(1, 20000);

        assertEq(token.balanceOf(address(managerInstance)), 20000);
        assertEq(token.balanceOf(alice), 280000);

        (, , uint256 valueOfLiquidity, ) = managerInstance.providers(
            1
        );

        assertEq(valueOfLiquidity, 20000);

        managerInstance.addLiquidity(1, 50000);

        assertEq(token.balanceOf(address(managerInstance)), 70000);
        assertEq(token.balanceOf(alice), 230000);

        (, , uint256 valueOfLiquidity2, ) = managerInstance.providers(
            1
        );

        assertEq(valueOfLiquidity2, 70000);
    }

    function testAddLiquidityFailsWhenProviderIDIsInvalid() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider();

        vm.expectRevert("Invalid provider ID");
        managerInstance.addLiquidity(2, 20000);
    }

    function testAddLiquidityFailsWhenCallerIsIncorrect() public {
        vm.startPrank(alice);

        token.mint(alice, 300000);
        token.approve(address(managerInstance), 300000);

        managerInstance.createNewLiquidityProvider();
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert("Not correct caller");
        managerInstance.addLiquidity(1, 20000);
        vm.stopPrank();

    }
}
