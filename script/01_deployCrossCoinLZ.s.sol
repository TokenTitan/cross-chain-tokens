// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import { CrossCoinLZ } from "../src/CrossCoinLZ.sol";
import { TransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract CrossCoinLZScript is Script {
    string private deploymentNetwork;

    address private proxyAdminAddr;
    address private proxyAddr;
    address private lzEndpointAddr;

    uint16 private chainId1;
    uint16 private chainId2;

    bool private forTest;

    function run() public {
        console.log("Deploying Cross Coin");

        // take values from the env if it is not a test environment
        if (!forTest) {
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

            string memory targetChain1 = vm.envString(string.concat("TARGET_CHAIN_1"));
            string memory targetChain2 = vm.envString(string.concat("TARGET_CHAIN_2"));

            lzEndpointAddr = vm.envAddress(
                string.concat("LZ_ENDPOINT_", deploymentNetwork)
            );

            chainId1 = uint16(vm.envUint(
                string.concat("CHAIN_ID_", targetChain1)
            ));

            chainId2 = uint16(vm.envUint(
                string.concat("CHAIN_ID_", targetChain2)
            ));
        }

        vm.startBroadcast();

        // deploy implementation contract
        address implementationAddr = address(new CrossCoinLZ());

        console.log(
            "Implementation contract deployed at",
            implementationAddr
        );

        // deploy proxy contract
        proxyAddr = address(
            new TransparentUpgradeableProxy(
                implementationAddr,
                proxyAdminAddr,
                abi.encodeWithSelector(
                    CrossCoinLZ(address(0)).initialize.selector,
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
        CrossCoinLZ(proxyAddr).transferOwnership(msg.sender);
        vm.stopBroadcast();
    }

    function deployForTest(
        address _proxyAdmin,
        address _lzEndpointAddr,
        uint16 _chainId1,
        uint16 _chainId2
    ) public returns (address) {
        // set state parameters for test deployment
        forTest = true;
        proxyAdminAddr = _proxyAdmin;
        lzEndpointAddr = _lzEndpointAddr;
        chainId1 = _chainId1;
        chainId2 = _chainId2;

        run();

        // reset state values
        forTest = false;
        proxyAdminAddr = address(0);
        lzEndpointAddr = address(0);
        chainId1 = 0;
        chainId1 = 0;

        return proxyAddr;
    }
}
