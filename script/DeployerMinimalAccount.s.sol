// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import { Script, console } from "../lib/forge-std/src/Script.sol";

import { MinimalAccount } from "../src/MinimalAccount.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

import { SendPacketUserOperation } from "../src/SendPacketUserOperation.s.sol";
import { EntryPoint } from "lib/account-abstraction/contracts/core/EntryPoint.sol";


contract DeployerMinimalAccount is Script {    
    function run() public returns (EntryPoint entryPoint, MinimalAccount minimalAccount, HelperConfig.NetworkConfigs memory networkConfig, SendPacketUserOperation sendPacketUserOperation) {
        HelperConfig helperConfig = new HelperConfig();
        helperConfig.run();
        networkConfig = helperConfig.getCurrentConfiguration();

        sendPacketUserOperation = new SendPacketUserOperation();

        vm.startBroadcast(networkConfig.accountAddressTest);
        
        entryPoint = new EntryPoint();
        minimalAccount = new MinimalAccount(address(entryPoint));

        vm.stopBroadcast();

        networkConfig.entryPointAddress = address(entryPoint);
    }
}