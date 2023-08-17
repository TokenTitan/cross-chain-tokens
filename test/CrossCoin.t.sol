// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/console.sol";

import { Test } from "forge-std/Test.sol";
import { CrossCoin } from "../src/CrossCoin.sol";
import { LZEndpointMock } from "src/mocks/LZEndpointMock.sol";

// deployment scripts
import { ProxyAdminScript } from "script/00_deployProxyAdmin.s.sol";
import { CrossCoinScript } from "script/01_deployCrossCoin.s.sol";

contract CrossCoinTest is Test {
    address public constant MOCK_USER_1 = address(1);
    address public constant MOCK_USER_2 = address(2);

    uint16 public constant CHAIN_ID_1 = 123;
    uint16 public constant CHAIN_ID_2 = 456;
    uint16 public constant CHAIN_ID_3 = 789;

    CrossCoin public crossCoin1;
    CrossCoin public crossCoin2;
    CrossCoin public crossCoin3;

    LZEndpointMock public lzEndPoint1;
    LZEndpointMock public lzEndPoint2;
    LZEndpointMock public lzEndPoint3;

    function setUp() public {
        ProxyAdminScript proxyAdminScript = new ProxyAdminScript();
        address proxyAdminAddr = proxyAdminScript.deployForTest();

        lzEndPoint1 = new LZEndpointMock(CHAIN_ID_1);
        lzEndPoint2 = new LZEndpointMock(CHAIN_ID_2);
        lzEndPoint3 = new LZEndpointMock(CHAIN_ID_3);

        CrossCoinScript crossCoinScript = new CrossCoinScript();

        crossCoin1 = CrossCoin(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(lzEndPoint1),
                CHAIN_ID_2,
                CHAIN_ID_3
            )
        );

        crossCoin2 = CrossCoin(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(lzEndPoint2),
                CHAIN_ID_1,
                CHAIN_ID_3
            )
        );

        crossCoin3 = CrossCoin(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(lzEndPoint3),
                CHAIN_ID_1,
                CHAIN_ID_2
            )
        );

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        console.log("Setting up endpoints...");
        lzEndPoint1.setDestLzEndpoint(address(crossCoin2), address(lzEndPoint2));
        lzEndPoint1.setDestLzEndpoint(address(crossCoin3), address(lzEndPoint3));

        lzEndPoint2.setDestLzEndpoint(address(crossCoin1), address(lzEndPoint1));
        lzEndPoint2.setDestLzEndpoint(address(crossCoin3), address(lzEndPoint3));

        lzEndPoint3.setDestLzEndpoint(address(crossCoin1), address(lzEndPoint1));
        lzEndPoint3.setDestLzEndpoint(address(crossCoin2), address(lzEndPoint2));
        console.log("Done.");

        // needs to be set after deployment
        console.log("Setting up trusted remote addresses...");
        crossCoin1.setTrustedRemoteAddress(CHAIN_ID_2, abi.encodePacked(address(crossCoin2)));
        crossCoin1.setTrustedRemoteAddress(CHAIN_ID_3, abi.encodePacked(address(crossCoin3)));

        crossCoin2.setTrustedRemoteAddress(CHAIN_ID_1, abi.encodePacked(address(crossCoin1)));
        crossCoin2.setTrustedRemoteAddress(CHAIN_ID_3, abi.encodePacked(address(crossCoin3)));

        crossCoin3.setTrustedRemoteAddress(CHAIN_ID_1, abi.encodePacked(address(crossCoin1)));
        crossCoin3.setTrustedRemoteAddress(CHAIN_ID_2, abi.encodePacked(address(crossCoin2)));
        console.log("Done.");
    }

    function testMint() public {
        crossCoin1.mint{value: 1 ether}(MOCK_USER_1, 100e18);
        assertTrue(crossCoin1.totalSupply() == 100e18);
        assertTrue(crossCoin2.totalSupply() == 100e18);
        assertTrue(crossCoin3.totalSupply() == 100e18);
    }
}
