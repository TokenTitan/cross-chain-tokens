// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/console.sol";

import { Test } from "forge-std/Test.sol";
import { CrossCoinHL } from "../src/CrossCoinHL.sol";
import { MailboxMock } from "src/mocks/MailboxMock.sol";

// deployment scripts
import { ProxyAdminScript } from "script/00_deployProxyAdmin.s.sol";
import { CrossCoinHLScript } from "script/02_deployCrossCoinHL.s.sol";

contract CrossCoinHLTest is Test {
    address public constant MOCK_USER_1 = address(1);
    address public constant MOCK_USER_2 = address(2);

    uint16 public constant CHAIN_ID_1 = 123;
    uint16 public constant CHAIN_ID_2 = 456;
    uint16 public constant CHAIN_ID_3 = 789;

    CrossCoinHL public crossCoin1;
    CrossCoinHL public crossCoin2;
    CrossCoinHL public crossCoin3;

    MailboxMock public mailbox1;
    MailboxMock public mailbox2;
    MailboxMock public mailbox3;

    function setUp() public {
        ProxyAdminScript proxyAdminScript = new ProxyAdminScript();
        address proxyAdminAddr = proxyAdminScript.deployForTest();

        mailbox1 = new MailboxMock(CHAIN_ID_1);
        console.log("Deployed mailbox for chain 1 at: ", address(mailbox1));
        mailbox2 = new MailboxMock(CHAIN_ID_2);
        console.log("Deployed mailbox for chain 2 at: ", address(mailbox2));
        mailbox3 = new MailboxMock(CHAIN_ID_3);
        console.log("Deployed mailbox for chain 3 at: ", address(mailbox3));

        CrossCoinHLScript crossCoinScript = new CrossCoinHLScript();

        crossCoin1 = CrossCoinHL(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(mailbox1),
                CHAIN_ID_2,
                CHAIN_ID_3
            )
        );

        crossCoin2 = CrossCoinHL(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(mailbox2),
                CHAIN_ID_1,
                CHAIN_ID_3
            )
        );

        crossCoin3 = CrossCoinHL(
            crossCoinScript.deployForTest(
                proxyAdminAddr,
                address(mailbox3),
                CHAIN_ID_1,
                CHAIN_ID_2
            )
        );

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        console.log("Setting up mailboxes...");
        mailbox1.addRemoteMailbox(CHAIN_ID_2, mailbox2);
        mailbox1.addRemoteMailbox(CHAIN_ID_3, mailbox3);

        mailbox2.addRemoteMailbox(CHAIN_ID_1, mailbox1);
        mailbox2.addRemoteMailbox(CHAIN_ID_3, mailbox3);

        mailbox3.addRemoteMailbox(CHAIN_ID_1, mailbox1);
        mailbox3.addRemoteMailbox(CHAIN_ID_2, mailbox2);
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

    function testTotalSupplyAcrossChains() public {
        crossCoin1.mint(MOCK_USER_1, 100e18);
        assertTrue(crossCoin1.totalSupply() == 100e18);
        assertTrue(crossCoin2.totalSupply() == 100e18);
        assertTrue(crossCoin3.totalSupply() == 100e18);

        crossCoin2.mint(MOCK_USER_2, 100e18);
        assertTrue(crossCoin1.totalSupply() == 200e18);
        assertTrue(crossCoin2.totalSupply() == 200e18);
        assertTrue(crossCoin3.totalSupply() == 200e18);

        crossCoin1.burn(MOCK_USER_1, 100e18);
        assertTrue(crossCoin1.totalSupply() == 100e18);
        assertTrue(crossCoin2.totalSupply() == 100e18);
        assertTrue(crossCoin3.totalSupply() == 100e18);

        crossCoin2.burn(MOCK_USER_2, 100e18);
        assertTrue(crossCoin1.totalSupply() == 0);
        assertTrue(crossCoin2.totalSupply() == 0);
        assertTrue(crossCoin3.totalSupply() == 0);
    }
}
