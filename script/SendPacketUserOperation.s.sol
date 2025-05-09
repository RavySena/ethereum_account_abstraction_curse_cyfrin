// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import { Script } from "../lib/forge-std/src/Script.sol";

import { MinimalAccount } from "../src/MinimalAccount.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract SendPacketUserOperation is Script {
    using MessageHashUtils for bytes32;

    uint256 private constant ANVIL_CHAINID = 31337;


    function run() public {}


    function signedPacketUserOperation(address minimalAccount, bytes calldata dataFuntion, HelperConfig.NetworkConfigs memory networkConfig) external view returns (PackedUserOperation memory packedUserOperation) {
        uint256 nonce = vm.getNonce(minimalAccount) - 1;

        bytes memory dataExecute = abi.encodeWithSelector(MinimalAccount.execute.selector, networkConfig.usdtAddress, 0, dataFuntion);

        packedUserOperation = _createPacketUserOperationUnsignatured(minimalAccount, nonce, dataExecute);

        bytes32 userOperationHash = IEntryPoint(networkConfig.entryPointAddress).getUserOpHash(packedUserOperation);
        bytes32 digest = userOperationHash.toEthSignedMessageHash();

        uint8 v;
        bytes32 r;
        bytes32 s;

        if (block.chainid == ANVIL_CHAINID) {
            (v, r, s) = vm.sign(networkConfig.accountPrivateKeyTest, digest);
        } else {
            (v, r, s) = vm.sign(networkConfig.accountAddressTest, digest);
        }

        packedUserOperation.signature = abi.encodePacked(r, s, v);
    }


    function _createPacketUserOperationUnsignatured(address _sender, uint256 _nonce, bytes memory _calldata) internal pure returns (PackedUserOperation memory packedUserOperation) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        
        packedUserOperation = PackedUserOperation({
            sender: _sender,
            nonce: _nonce,
            initCode: "",
            callData: _calldata,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: "",
            signature: ""
        });
    }
}





















