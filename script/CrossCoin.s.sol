// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import { CrossCoin } from "../src/CrossCoin.sol";
import { TransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract CrossCoinScript is Script {
    string private deploymentNetwork;
    address private proxyAdminAddr;
    address private proxyAddr;
    bool private forTest;

    function run() public {
        console.log("Deploying Cross Coin");

        if (forTest) {
            address implementationAddr = address(new CrossCoin());

            console.log(
                "Implementation contract deployed at",
                implementationAddr
            );

            proxyAddr = address(
                new TransparentUpgradeableProxy(
                    implementationAddr,
                    proxyAdminAddr,
                    abi.encodeWithSelector(
                        CrossCoin(address(0)).initialize.selector
                    )
                )
            );
        } else {
            deploymentNetwork = vm.envString(
                "DEPLOYMENT_NETWORK"
            );
            proxyAdminAddr = vm.envAddress(
                string.concat("PROXY_ADMIN_ADDR_", deploymentNetwork)
            );

            vm.broadcast();
            address implementationAddr = address(new CrossCoin());

            console.log(
                "Implementation contract deployed at",
                implementationAddr
            );


            proxyAddr = address(
                new TransparentUpgradeableProxy(
                    implementationAddr,
                    proxyAdminAddr,
                    abi.encodeWithSelector(
                        CrossCoin(address(0)).initialize.selector
                    )
                )
            );
        }
        vm.stopBroadcast();
    }

    function deployForTest(
        address proxyAdmin
    ) public returns (address) {
        forTest = true;
        proxyAdminAddr = proxyAdmin;
        run();
        forTest = false;
        return proxyAddr;
    }
}
