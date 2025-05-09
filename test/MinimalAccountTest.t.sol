// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import { Test } from "../lib/forge-std/src/Test.sol";

import { MinimalAccount } from "../src/MinimalAccount.sol";
import { DeployerMinimalAccount } from "../script/DeployerMinimalAccount.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { SendPacketUserOperation } from "../src/SendPacketUserOperation.s.sol";

import { IERC20 } from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS } from "lib/account-abstraction/contracts/core/Helpers.sol";


contract MinimalAccountTest is Test {
    MinimalAccount public minimalAccount;
    IEntryPoint public entryPoint;
    HelperConfig.NetworkConfigs public networkConfigs;
    SendPacketUserOperation public sendPacketUserOperation;


    address public user = makeAddr("user");


    function setUp() public {
        DeployerMinimalAccount deployer = new DeployerMinimalAccount();
        (entryPoint, minimalAccount, networkConfigs, sendPacketUserOperation) = deployer.run();

        vm.deal(address(minimalAccount), 100 ether);
    }


    function testCallerIsTheEntrypointAndValidSignature() public {
        bytes memory dataFuntion = abi.encodeWithSelector(ERC20Mock.mint.selector, minimalAccount, 10 ether);
        PackedUserOperation memory packedUserOperation = sendPacketUserOperation.signedPacketUserOperation(address(minimalAccount), dataFuntion, networkConfigs);
        
        bytes32 userOperationHash = IEntryPoint(networkConfigs.entryPointAddress).getUserOpHash(packedUserOperation);

        vm.prank(networkConfigs.entryPointAddress);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOperation, userOperationHash, 0);

        assertEq(validationData, SIG_VALIDATION_SUCCESS);
    }


    function testCallerIsNotTheEntryPoint() public {
        bytes memory dataFuntion = abi.encodeWithSelector(ERC20Mock.mint.selector, minimalAccount, 10 ether);
        PackedUserOperation memory packedUserOperation = sendPacketUserOperation.signedPacketUserOperation(address(minimalAccount), dataFuntion, networkConfigs);

        bytes32 userOperationHash = IEntryPoint(networkConfigs.entryPointAddress).getUserOpHash(packedUserOperation);

        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__InvalidCaller.selector));
        minimalAccount.validateUserOp(packedUserOperation, userOperationHash, 0);
    }


    function testFullFunctionality() public {
        bytes memory dataFuntion = abi.encodeWithSelector(ERC20Mock.mint.selector, minimalAccount, 10 ether);
        PackedUserOperation memory packedUserOperation = sendPacketUserOperation.signedPacketUserOperation(address(minimalAccount), dataFuntion, networkConfigs);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOperation;

        IEntryPoint(networkConfigs.entryPointAddress).handleOps(ops, payable(msg.sender));

        uint256 balance = IERC20(networkConfigs.usdtAddress).balanceOf(address(minimalAccount));

        assertEq(balance, 10 ether);
    }
}