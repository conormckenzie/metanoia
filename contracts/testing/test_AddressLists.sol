// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Address Lists.sol";
import "hardhat/console.sol";

contract test_AddressLists is AddressLists {
    function addresses_length(uint listIndex) public view returns(uint) {
        return addressLists[listIndex].length;
    }
    function addresses_list(uint id, uint listIndex) public view returns(address) {
        return addressLists[listIndex].list[id];
    }
    function addresses_listInv(address _address, uint listIndex) public view returns(uint) {
        return addressLists[listIndex].listInv[_address];
    }
}