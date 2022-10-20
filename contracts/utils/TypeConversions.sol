// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library TypeConversions {
    // (X) to string

    // source: custom-built
	function boolToString(bool _b) internal pure returns (string memory _boolAsString) {
		if (_b) {
			return "true";
		} else {
			return "false";
		}
	}  

    // source: using OpenZeppelin's `Strings` library
	function uintToString(uint _u) internal pure returns (string memory _uintAsString) {
		return Strings.toString(_u);
	}

    // source: custom-built
    function intToString(int _i) internal pure returns (string memory _intAsString) {
        if (_i < 0) {
            return string(abi.encodePacked("-", uintToString(uint(-1*_i))));
        }
        else {
            return uintToString(uint(_i));
        }
    }

    // source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function addressToString(address _a) internal pure returns (string memory _addressAsString) {
        return Strings.toHexString(uint160(_a), 20);
    }

    // source: https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory _bytes32AsString) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    // bytes to (X)

    // source: custom-built
    function bytesToBool(bytes memory _B) internal pure returns (bool) {
        if (keccak256(_B) == keccak256(bytes(""))) {
            return false;
        }
        else {
            return true;
        }
    }

    // source: https://ethereum.stackexchange.com/questions/51229/how-to-convert-bytes-to-uint-in-solidity
    function bytesToUint(bytes memory _B) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<_B.length;i++){
            number = number + uint(uint8(_B[i]))*(2**(8*(_B.length-(i+1))));
        }
        return number;
    }

    // source: custom-built (uses `bytesToUint` implementation above)
    // assuming twos-complement representation of negative numbers
    function bytesToInt (bytes memory _B) internal pure returns (int) {
        uint256 unsigned = bytesToUint(_B);
        int256 signed;
        if (unsigned >> 255 == 1) {
            signed = int256(unsigned % (2**255)) - (2*255);
        }
        return signed;
    }

    // source: https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity
    function bytesToAddress (bytes memory _B) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_B,20))
        } 
    }

    // solhint-disable-next-line
    // source: https://stackoverflow.com/questions/59243982/how-to-correct-convert-bytes-to-bytes32-and-then-convert-back/74046104#74046104
    function bytesToBytes32 (bytes memory _B) internal pure returns (bytes32 _B32) {
        if (_B.length == 0) {
            return 0x0;
        }
        assembly {
            _B32 := mload(add(_B,32))
        } 
    }

    // source: custom-built
    // assuming the string was encoded directly into bytes representation via the solidity/EVM default
    function bytesToString (bytes memory _B) internal pure returns (string memory _s) {
        return string(_B);
    }

    // (X) to bytes

    // source: custom-built
    function boolToBytes(bool _b) internal pure returns (bytes memory _B) {
        if (_b) {
            _B[0] = 0x01;
        }
        else {
            _B[0] = 0x00;
        }
    }

    // source: https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
    function uintToBytes(uint _u) internal pure returns (bytes memory _B) {
        return abi.encodePacked(_u);
    }

    // source: same ideas as used in `uintToBytes`
    function intToBytes(int _i) internal pure returns (bytes memory _B) {
        return abi.encodePacked(_i);
    }

    // source: same ideas as used in `uintToBytes`
    function addressToBytes(address _a) internal pure returns (bytes memory _B) {
        return abi.encodePacked(_a);
    }

    // source: custom-built
    function bytes32ToBytes(bytes32 _B32) internal pure returns (bytes memory _B) {
        return abi.encodePacked(_B32);
    }
    
    // source: custom-built
    function StringToBytes(string memory _s) internal pure returns (bytes memory _B) {
        return bytes(_s);
    }


}