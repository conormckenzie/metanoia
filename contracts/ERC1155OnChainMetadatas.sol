// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./utils/TypeUtils.sol";
import "./utils/Base64.sol";
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