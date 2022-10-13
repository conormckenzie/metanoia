// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ERC1155 & marketplace compatibility
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EmergencyPausable.sol";

// type conversions
import "./utils/TypeConversions.sol";

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    //would be good to remove the inline assembly
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

interface ICustomTypeHandler {
    function isKnownType(string memory attributeType) external view returns (bool);
    function typeToString(string memory _type, bytes memory _typeDataInBytes) external view returns (string memory);
}

interface IUriProvider {
    function uri(uint nftId) external view returns (bool);
}

contract OnChainTestNft is 
    ERC1155Supply, 
    ERC2981ContractWideRoyalties, 
    Ownable,
    ReentrancyGuard, 
    EmergencyPausable
{
    string public constant name = "Metanoia Test Nft";
    string public constant symbol = "METANOIA-TEST-NFT";

    // points to an contract which handles custom or non-standard types 
    ICustomTypeHandler customTypeHandler;
    
    address[] authorizedAddresses;

    // AttributeContext provides the name and variable type for a given attribute in `attributes` 
    // with the same numeric ID
    struct AttributeContext {
        string attributeName;
        string attributeType;
    }

    struct AttributeContextList {
        AttributeContext[] context_fromID;
        mapping(string => uint) ID_fromName;
    }
    AttributeContextList attributeContexts;

    // maps NFT ID to the attribute list for that NFT
    mapping(uint => mapping(uint => bytes)) attributes;

    constructor() ERC1155("") {
        // initialize();
    }

    function initialize() public virtual override initializer {
        customTypeHandler = ICustomTypeHandler(address(this));

        super.initialize();
    }

    // DEVNOTE: incomplete formatting - need to massage to fit into OpenSea's expected format
    // DEVNOTE: can condense?
	function uri(uint256 nftId) override(ERC1155) public view returns (string memory) {
		string memory _uriString = '{';

        // loop over all registered attributes
        for (uint i = 0; i < attributeContexts.context_fromID.length; i++) {
            bool matchedType;
            // for each attribute, if the value of that attribute for that ID is not the default value,
            // then add the NAME and VALUE (converted from bytes to the attribute's TYPE then to string)

            // bool
            if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bool"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.boolToString(TypeConversions.bytesToBool(attributes[nftId][i]))
                ));
                matchedType = true;
            }

            // uint
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("uint")) ||
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("uint256"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.uintToString(TypeConversions.bytesToUint(attributes[nftId][i]))
                ));
                matchedType = true;
            }

            // int
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("int")) ||
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("int256"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.intToString(TypeConversions.bytesToInt(attributes[nftId][i]))
                ));
                matchedType = true;
            }

            // address
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("address"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.addressToString(TypeConversions.bytesToAddress(attributes[nftId][i]))
                ));
                matchedType = true;
            }

            // bytes32
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bytes32"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.bytes32ToString(TypeConversions.bytesToBytes32(attributes[nftId][i]))
                ));
                matchedType = true;
            }

            // string
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bytes32"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '"', attributeContexts.context_fromID[i].attributeName, '": "',
                    TypeConversions.bytesToString(attributes[nftId][i])
                ));
                matchedType = true;
            }

            // custom types
            else if (address(customTypeHandler) != address(this)) { 
                // this contract does not handle types by implementing the functions defined in the customTypeHandler
                // interface, so skip this step if this contract is the customTypeHandler 
                if (customTypeHandler.isKnownType(attributeContexts.context_fromID[i].attributeType)) {
                    _uriString = string(abi.encodePacked(
                        _uriString, 
                        '"', attributeContexts.context_fromID[i].attributeName, '": "',
                        customTypeHandler.typeToString(
                            attributeContexts.context_fromID[i].attributeType, 
                            attributes[nftId][i]
                        )
                    ));
                    matchedType = true;
                } 
            }

            require(
                matchedType,
                "listed type does not match with any known type"
            );
        }

        //-----
        string memory json = Base64.encode(
			bytes(string(abi.encodePacked('{',
				// '"name": "', attributes[nftId].name, '",',
				// '"image": "', attributes[nftId].imageUri, '",',
				// '"description": "', attributes[nftId].description, '",',
				// '"attributes": [',
				// 	'{"trait_type": "NFT Type", "value": ', uintToString(attributes[nftId].nftType), '},',
				// 	'{"trait_type": "Infinite Redemptions", "value": ', boolToString(attributes[nftId].infiniteRedemptions), '},',
				// 	'{"trait_type": "Redemptions", "value": ', uintToString(attributes[nftId].redemptions), '}',
				']}'
			)))
		);
		return string(abi.encodePacked('data:application/json;base64,', json));
	}  

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }


}