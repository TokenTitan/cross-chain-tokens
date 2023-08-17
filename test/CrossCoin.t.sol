// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossCoin.sol";

contract CrossCoinTest is Test {
    CrossCoin public crossCoin;

    function setUp() public {
        crossCoin = new CrossCoin();
        crossCoin.setNumber(0);
    }

    function testIncrement() public {
        crossCoin.increment();
        assertEq(crossCoin.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        crossCoin.setNumber(x);
        assertEq(crossCoin.number(), x);
    }
}
