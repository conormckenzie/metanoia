// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract OnChainNft is ERC1155Supply {
    mapping(uint256 => Attr) public attributes; // maps nft id to that nft's attributes

    uint public nextTokenID = 1;

    string public symbol;
    
    mapping(uint => string) uriList;

    struct Attr {

        // Add any custom fields you want here. 
        // A default set of commonly included fields are provided, feel free to comment these out.
        // Make sure to edit the uri function to include any new fields and exclude any unwanted fields.
        // Make sure to edit the setAttributes function to include any new fields and exclude any unwanted fields.
        // Alternatively, list any fields in otherFields and they will automatically be included in the uri.

        string name;
        // string symbol;
        // uint nftType;
        // bool infiniteRedemptions;
        // uint redemptions;
        string description;
        string imageUri;
        GenericDataType[] moreFields;
    }

    struct GenericDataType {
        string name;
        string dataType;
        bytes data;
        bool _active;
    }

    string[] recognizedTypes = ["bool", "uint", "int", "address", "string", "bytes"];

    // string[] private empty_stringArray;
    // bytes[] private empty_bytesArray;

    function _mintWithAttributes (
        address to, 
        uint256 id, 
        uint256 amount,
        bytes memory data, 
        string memory name,
        string memory description,
        string memory imageUri,
        uint[] memory extraFieldsToSet,
        string[] memory extraAttributes_names,
        string[] memory extraAttributes_dataTypes,
        bytes[] memory extraAttributes_datas
    ) internal virtual {
        require (!exists(id), "Cannot change metadata of existing token");
        _mint(to, id, amount, data);
        
        setAttributes(
            id, name, description, imageUri, 
            extraFieldsToSet, extraAttributes_names, extraAttributes_dataTypes, extraAttributes_datas
        );
    }

    function _mintWithoutAttributes (
        address to, 
        uint256 id, 
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require (exists(id), "Please provide metadata for new token");
        _mint(to, id, amount, data);
    }

    function setAttributes (
        uint id, 
        string memory name,
        string memory description,
        string memory imageUri,
        uint[] memory extraFieldsToSet,
        string[] memory extraFields_name,
        string[] memory extraFields_dataType,
        bytes[] memory extraFields_data
    ) internal {
        require(
            extraFields_name.length == extraFields_dataType.length &&
            extraFields_dataType.length == extraFields_data.length,
            "extraFields_name, extraFields_dataType, and extraFields_data must be the same length."
        );
        for (uint i = 0; i < extraFieldsToSet.length; i++) {
            bool recognizedType;
            for (uint j = 0; j < recognizedTypes.length; j++) {
                if (TypeUtils.compareStrings(extraFields_dataType[extraFieldsToSet[i]], recognizedTypes[j])) {
                    recognizedType = true;
                    break;
                }
            }
            require(recognizedType, "extraFields_dataType[i] is not a recognized data type");
        }
        attributes[id].name = name;
        attributes[id].description = description;
        attributes[id].imageUri = imageUri;
        for (uint i = 0; i < extraFieldsToSet.length; i++) {
            attributes[id].moreFields[extraFieldsToSet[i]].name = extraFields_name[extraFieldsToSet[i]];
            attributes[id].moreFields[extraFieldsToSet[i]].dataType = extraFields_dataType[extraFieldsToSet[i]];
            attributes[id].moreFields[extraFieldsToSet[i]].data = extraFields_data[extraFieldsToSet[i]];
            attributes[id].moreFields[extraFieldsToSet[i]]._active = true;
        }
    }

	function uri(uint256 nftId) override(ERC1155) public view returns (string memory) {
        string[] memory preJsonComponents;
        string memory jsonAttributes;

        for (uint i = 0; i < attributes[nftId].moreFields.length; i++) {
            string memory trailingComma;
            if (i == attributes[nftId].moreFields.length - 1) {
                trailingComma = ",";
            }
            // preJsonComponents[i] = string(abi.encodePacked(
            //     '{"trait_type": ', 
            //     attributes[nftId].otherFields[i].name, 
            //     ', "value": ', 
            //     TypeUtils.typeToString(
            //         attributes[nftId].otherFields[i].data, attributes[nftId].otherFields[i].dataType
            //     ), 
            //     '}',
            //     trailingComma
            // ));
            jsonAttributes = string(abi.encodePacked(
                jsonAttributes,
                '{"trait_type": ', 
                attributes[nftId].moreFields[i].name, 
                ', "value": ', 
                TypeUtils.typeToString(attributes[nftId].moreFields[i].data, attributes[nftId].moreFields[i].dataType), 
                '}',
                trailingComma
            ));
        }

        for (uint i = 0; i < preJsonComponents.length; i++) {

        }
		string memory json = Base64.encode(
			bytes(string(abi.encodePacked('{',
				'"name": "', attributes[nftId].name, '",',
				'"image": "', attributes[nftId].imageUri, '",',
				'"description": "', attributes[nftId].description, '",',

				'"attributes": [',
					// '{"trait_type": "NFT Type", "value": ', uint2str(attributes[nftId].nftType), '},',
                    // solhint-disable-next-line max-line-length
					// '{"trait_type": "Infinite Redemptions", "value": ', bool2str(attributes[nftId].infiniteRedemptions), '},',
					// '{"trait_type": "Redemptions", "value": ', uint2str(attributes[nftId].redemptions), '}',
                    jsonAttributes,
				']',
            '}')))
		);
		return string(abi.encodePacked('data:application/json;base64,', json));
	}  
}

library TypeUtils {
    int256 constant MIN_INT = -2**255;

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function typeToString(bytes memory _data, string memory _dataType) 
    internal pure returns(string memory _dataAsString) {
        if (compareStrings(_dataType, "bool")) {
            return boolToString(bytesToBool(_data));
        }
        else if (compareStrings(_dataType, "uint")) {
            return Strings.toString(bytesToUint(_data));
        }
        else if (compareStrings(_dataType, "int")) {
            return intToString(int(bytesToUint(_data)));
        }
        else if (compareStrings(_dataType, "address")) {
            return Strings.toHexString(bytesToAddress(_data));
        }
        else if (compareStrings(_dataType, "string")) {
            return string(_data);
        }
        else if (compareStrings(_dataType, "bytes")) {
            return bytesToString(_data);
        }
        else {
            revert("TypeUtils: typeToString: unrecognized dataType provided");
        }
    }

	function boolToString(bool _b) internal pure returns (string memory _boolAsString) {
		if (_b) {
			return "true";
		} else {
			return "false";
		}
	}  

    function intToString(int _si) internal pure returns (string memory _intAsString) {
        if (_si < 0) {
            return string(abi.encodePacked("-", Strings.toString(uint(~_si) + 1)));
        }
        else {
            return Strings.toString(uint(_si));
        }
    }

    // function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
	// 	return Strings.toString(_i);
	// }

    // function addressToString(address _a) internal pure returns (string memory _addressAsString) {
    //     return Strings.toHexString(_a);
    // }

    function bytesToString(bytes memory byteCode) internal pure returns(string memory stringData) {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function bytesToBool(bytes memory b) internal pure returns (bool){
        require(b.length == 1,"The given bytes have length > 1 and should not be interpretted as a bool");
        if (b[0] == 0x00) {
            return false;
        }
        else if (b[0] == 0x01) {
            return true;
        }
        else {
            revert("The given bytes have first byte != 0x00 or 0x01 and should not be interpretted as a bool");
        }
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
        addr := mload(add(bys,20))
        } 
    }
}

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}