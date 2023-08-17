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
            console.log(
                "Cross Chain proxy deployed at",
                proxyAddr
            );
        } else {
            deploymentNetwork = vm.envString(
                "DEPLOYMENT_NETWORK"
            );

            if (bytes(deploymentNetwork).length == 0) {
                revert("Deployment network is not set in .env file");
            }
            if (
                bytes(
                    vm.envString(
                        string.concat("PROXY_ADMIN_ADDR_", deploymentNetwork)
                    )
                ).length == 0
            ) {
                revert("ProxyAdmin address is not set in .env file");
            }

            proxyAdminAddr = vm.envAddress(
                string.concat("PROXY_ADMIN_ADDR_", deploymentNetwork)
            );

            vm.startBroadcast();
            address implementationAddr = address(new CrossCoin());

            console.log(
                "Implementation contract deployed at",
                implementationAddr
            );

            string memory targetChain1 = vm.envString(string.concat("TARGET_CHAIN_1"));
            string memory targetChain2 = vm.envString(string.concat("TARGET_CHAIN_2"));

            address lzEndpointAddr = vm.envAddress(
                string.concat("LZ_ENDPOINT_", deploymentNetwork)
            );

            uint16 chainId1 = uint16(vm.envUint(
                string.concat("CHAIN_ID_", targetChain1)
            ));

            uint16 chainId2 = uint16(vm.envUint(
                string.concat("CHAIN_ID_", targetChain2)
            ));

            proxyAddr = address(
                new TransparentUpgradeableProxy(
                    implementationAddr,
                    proxyAdminAddr,
                    abi.encodeWithSelector(
                        CrossCoin(address(0)).initialize.selector,
                        "CrossCoin",
                        "CC",
                        lzEndpointAddr,
                        [chainId1, chainId2]
                    )
                )
            );
            console.log(
                "Cross Chain proxy deployed at",
                proxyAddr
            );
        }
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
