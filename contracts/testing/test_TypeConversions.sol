// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/TypeConversions.sol";

contract testTypeConversions {

	    function tryBoolToString(bool _b) public pure returns (string memory _boolAsString) {
	        return TypeConversions.boolToString(_b);
	    }

        function tryUintToString(uint _u) public pure returns (string memory _uintAsString) {
            return TypeConversions.uintToString(_u);
        }

        function tryIntToString(int _i) public pure returns (string memory _intAsString) {
            return TypeConversions.intToString(_i);
        }
        
        function tryAddressToString(address _a) public pure returns (string memory _addressAsString) {
            return TypeConversions.addressToString(_a);
        }

        function tryBytes32ToString(bytes32 _bytes32) public pure returns (string memory _bytes32AsString) {
            return TypeConversions.bytes32ToString(_bytes32);
        }

        function tryBytesToBool(bytes memory _B) public pure returns (bool) {
            return TypeConversions.bytesToBool(_B);
        }

        function tryBytesToUint(bytes memory _B) public pure returns (uint256){
            return TypeConversions.bytesToUint(_B);
        }

        function tryBytesToInt(bytes memory _B) public pure returns (int) {
            return TypeConversions.bytesToInt(_B);
        }

        function tryBytesToAddress(bytes memory _B) public pure returns (address addr) {
            return TypeConversions.bytesToAddress(_B);
        }

        function tryBytesToBytes32(bytes memory _B) public pure returns (bytes32 _B32) {
            return TypeConversions.bytesToBytes32(_B);
        }

        function tryBytesToString (bytes memory _B) public pure returns (string memory _s) {
            return TypeConversions.bytesToString(_B);
        }

        function tryBoolToBytes(bool _b) public pure returns (bytes memory _B) {
            return TypeConversions.boolToBytes(_b);
        }

        function tryUintToBytes(uint _u) public pure returns (bytes memory _B) {
            return TypeConversions.uintToBytes(_u);
        }

        function tryIntToBytes(int _i) public pure returns (bytes memory _B) {
            return TypeConversions.intToBytes(_i);
        }

        function tryAddressToBytes(address _a) public pure returns (bytes memory _B) {
            return TypeConversions.addressToBytes(_a);
        }

        function trybytes32ToBytes(bytes32 _B32) public pure returns (bytes memory _B) {
            return TypeConversions.bytes32ToBytes(_B32);
        }

        function tryStringToBytes(string memory _s) public pure returns (bytes memory _B) {
            return TypeConversions.StringToBytes(_s);
        }
}
