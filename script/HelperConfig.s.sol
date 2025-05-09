// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import { Script } from "../lib/forge-std/src/Script.sol";

import { EntryPoint } from "lib/account-abstraction/contracts/core/EntryPoint.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract HelperConfig is Script {
    uint256 private constant ANVIL_CHAINID = 31337;
    address private constant ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    address private constant ACCOUNT = address(0); // YOUR_ACCOUNT_ADDRESS


    struct NetworkConfigs{
        address entryPointAddress;
        address accountAddressTest;
        uint256 accountPrivateKeyTest;
        address usdtAddress;
    }


    NetworkConfigs public currentConfiguration;


    function run() public {
        if (block.chainid == ANVIL_CHAINID) {
            getConfigAnvil();
        } else {
            currentConfiguration = NetworkConfigs({
                entryPointAddress: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
                accountAddressTest: ACCOUNT,
                accountPrivateKeyTest: 0,
                usdtAddress: 0x271B34781c76fB06bfc54eD9cfE7c817d89f7759
            });
        }

    }


    function getConfigAnvil() public {
        vm.startBroadcast();
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        
        ERC20Mock usdt = new ERC20Mock();

        currentConfiguration = NetworkConfigs({
            entryPointAddress: address(entryPoint),
            accountAddressTest: ANVIL_ACCOUNT,
            accountPrivateKeyTest: ANVIL_PRIVATE_KEY,
            usdtAddress: address(usdt)
        });
    }


    function getCurrentConfiguration() public view returns (NetworkConfigs memory) {
        return currentConfiguration;
    }

}