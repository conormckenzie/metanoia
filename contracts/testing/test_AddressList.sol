// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Address List.sol";
import "hardhat/console.sol";

contract test_AddressList is _AddressList {
    function addresses_length() public view returns(uint) {
        return addresses.length;
    }
    function addresses_list(uint id) public view returns(address) {
        return addresses.list[id];
    }
    function addresses_listInv(address _address) public view returns(uint) {
        return addresses.listInv[_address];
    }
}