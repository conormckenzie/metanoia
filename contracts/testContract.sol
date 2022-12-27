// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'hardhat/console.sol';

contract conortest {
    function testFail() public view {
        console.log("Test succeeded:1A");
        require(false, "best");
        console.log("Test succeeded:1B");
    }
}