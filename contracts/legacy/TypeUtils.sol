// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Strings.sol";

// library TypeUtils {
//     int256 constant MIN_INT = -2**255;

//     function compareStrings(string memory a, string memory b) internal pure returns (bool) {
//         return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
//     }

//     function typeToString(bytes memory _data, string memory _dataType) 
//     internal pure returns(string memory _dataAsString) {
//         if (compareStrings(_dataType, "bool")) {
//             return boolToString(bytesToBool(_data));
//         }
//         else if (compareStrings(_dataType, "uint")) {
//             return Strings.toString(bytesToUint(_data));
//         }
//         else if (compareStrings(_dataType, "int")) {
//             return intToString(int(bytesToUint(_data)));
//         }
//         else if (compareStrings(_dataType, "address")) {
//             return Strings.toHexString(bytesToAddress(_data));
//         }
//         else if (compareStrings(_dataType, "string")) {
//             return string(_data);
//         }
//         else if (compareStrings(_dataType, "bytes")) {
//             return bytesToString(_data);
//         }
//         else {
//             revert("TypeUtils: typeToString: unrecognized dataType provided");
//         }
//     }

// 	function boolToString(bool _b) internal pure returns (string memory _boolAsString) {
// 		if (_b) {
// 			return "true";
// 		} else {
// 			return "false";
// 		}
// 	}  

//     function intToString(int _si) internal pure returns (string memory _intAsString) {
//         if (_si < 0) {
//             return string(abi.encodePacked("-", Strings.toString(uint(~_si) + 1)));
//         }
//         else {
//             return Strings.toString(uint(_si));
//         }
//     }

//     // function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
// 	// 	return Strings.toString(_i);
// 	// }

//     // function addressToString(address _a) internal pure returns (string memory _addressAsString) {
//     //     return Strings.toHexString(_a);
//     // }

//     function bytesToString(bytes memory byteCode) internal pure returns(string memory stringData) {
//         uint256 blank = 0; //blank 32 byte value
//         uint256 length = byteCode.length;

//         uint cycles = byteCode.length / 0x20;
//         uint requiredAlloc = length;

//         if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
//         {
//             cycles++;
//             requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
//         }

//         stringData = new string(requiredAlloc);

//         //copy data in 32 byte blocks
//         assembly {
//             let cycle := 0

//             for
//             {
//                 let mc := add(stringData, 0x20) //pointer into bytes we're writing to
//                 let cc := add(byteCode, 0x20)   //pointer to where we're reading from
//             } lt(cycle, cycles) {
//                 mc := add(mc, 0x20)
//                 cc := add(cc, 0x20)
//                 cycle := add(cycle, 0x01)
//             } {
//                 mstore(mc, mload(cc))
//             }
//         }

//         //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
//         if (length % 0x20 > 0)
//         {
//             uint offsetStart = 0x20 + length;
//             assembly
//             {
//                 let mc := add(stringData, offsetStart)
//                 mstore(mc, mload(add(blank, 0x20)))
//                 //now shrink the memory back so the returned object is the correct size
//                 mstore(stringData, length)
//             }
//         }
//     }

//     function bytesToBool(bytes memory b) internal pure returns (bool){
//         require(b.length == 1,"The given bytes have length > 1 and should not be interpretted as a bool");
//         if (b[0] == 0x00) {
//             return false;
//         }
//         else if (b[0] == 0x01) {
//             return true;
//         }
//         else {
//             revert("The given bytes have first byte != 0x00 or 0x01 and should not be interpretted as a bool");
//         }
//     }

//     function bytesToUint(bytes memory b) internal pure returns (uint256){
//         uint256 number;
//         for(uint i=0;i<b.length;i++){
//             number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
//         }
//         return number;
//     }

//     function bytesToAddress(bytes memory bys) private pure returns (address addr) {
//         assembly {
//         addr := mload(add(bys,20))
//         } 
//     }
// }