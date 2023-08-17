// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable";

contract CrossCoin {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
