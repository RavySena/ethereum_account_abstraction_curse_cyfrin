// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS } from "lib/account-abstraction/contracts/core/Helpers.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract MinimalAccount is IAccount, Ownable {
    using MessageHashUtils for bytes32;

    /*------------------------------------------ TYPE DECLARATIONS -------------------------------------------*/
    IEntryPoint private immutable i_entryPoint;


    /*------------------------------------------------ ERRORS ------------------------------------------------*/
    error MinimalAccount__InvalidCaller();
    error MinimalAccount__ExecutionFailed();


    /*---------------------------------------------- MODIFIERS -----------------------------------------------*/
    modifier EntryPointCaller() {
        if (msg.sender != address(i_entryPoint)){
            revert MinimalAccount__InvalidCaller();
        }
        _;
    }


    modifier EntryPointOrOwnerCaller() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()){
            revert MinimalAccount__InvalidCaller();
        }
        _;
    }


    constructor(address entryPointAddress) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPointAddress);
    }


    receive() external payable {}


    /*------------------------------------------         -----------------------------------------------------*/
    /*------------------------------------------ FUNCTIONS EXTERNAL ------------------------------------------*/
    /*----------------------------------------------------          ------------------------------------------*/
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external EntryPointCaller() returns (uint256 validationData) {
        uint256 success = _validateUserOp(userOp, userOpHash);

        if (SIG_VALIDATION_SUCCESS == success) {
            _payPrefund(missingAccountFunds);
            return SIG_VALIDATION_SUCCESS;
        }

        return SIG_VALIDATION_FAILED;
    }


    function execute(address dest, uint256 value, bytes calldata functionData) external EntryPointOrOwnerCaller() {        
        (bool sucess,) = dest.call{value: value}(functionData);
        if (!sucess) {
            revert MinimalAccount__ExecutionFailed();
        }
    }


    /*-----------------------------------               ------------------------------------------------------*/
    /*----------------------------------- FUNCTIONS INTERNAL AND PRIVATES ------------------------------------*/
    /*---------------------------------------------------                 ------------------------------------*/
    function _validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns (uint256) {
        bytes32 messageEthHash = userOpHash.toEthSignedMessageHash();
        (address signer,,) = ECDSA.tryRecover(messageEthHash, userOp.signature);

        if (signer == owner()) {
            return SIG_VALIDATION_SUCCESS;
        }

        return SIG_VALIDATION_FAILED;
    }


    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }
}