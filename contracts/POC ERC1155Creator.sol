//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// WARNING: Access control has been disabled for this proof of concept.

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNfts is ERC1155MultiUri {
    address public extrasHolder = address(this);
    
    uint public constant initialSupply = 0;
    uint public totalSupply = initialSupply;
    uint public nextTokenID = 1;

    string public name;
    string public symbol;
    mapping(uint => string) uriList;
    mapping(uint => Attr) public attributes;

    struct Attr {
        string name;
        string symbol;
        uint nftType;
        bool infiniteRedemptions;
        uint redemptions;
        string description;
        string imageUri;
    }

    function getNftType(uint nftId) external view returns (uint) {
        return attributes[nftId].nftType;
    }
    
    constructor() ERC1155("https://5onxwdchjdxmgedt32sk5viwzfqxhhsycntmfoqiowaswrblkt7a.arweave.net/65t7DEdI7sMQc96krtUWyWFznlgTZsK6CHWBK0QrVP4") {

        name = "Metanoia NFT";
        symbol = "METANOIA-NFT";

        // 1: single-use redeemable NFT
        // 2: multi-use redeemable NFT
        // 3: infinitely redeemable NFT
        uriList[1] = "single-use";
        uriList[2] = "multi-use";
        uriList[3] = "infinite-use";
    }

    function mintNewTicketCollection(address to, uint amount, uint nftType) public /*onlyOwner*/ {
        require(nftType >= 1 && nftType <= 3, "NFT type must be between 1 and 3");
        require(!(nftType == 3 && amount > 1),"An NFT of type 3 must be unique");
        nextTokenID++;
        totalSupply += amount;
        _mintWithAttributes(to, nextTokenID-1, amount, "", uriList[nftType], nftType);
    }

    function _mintWithAttributes (
        address to, 
        uint256 id, 
        uint256 amount,
        bytes memory data, 
        string memory newuri,
        uint nftType
    ) internal virtual {
        require (!exists(id), "Cannot change metadata of existing token");
        _mintWithURI(to, id, amount, data, newuri);
        setAttributes(id, nftType, 3);
    }

    function setAttributes (uint id, uint nftType, uint redemptions) internal {
        attributes[id].description = "A ticket given to the first ever 100 settlers to set foot on Metanoia. It is rumoured that the original owners had to make extreme sacrifices to obtain them, and that the holders of these tickets might have unknown, but pleasant surprises that await them in the future.";
        attributes[id].imageUri = "https://bafybeiaxjatdky2wc75dvimchxpmbf74ba7bnj7ixgntpb6pujofet2zyy.ipfs.infura-ipfs.io/ticket1-01.png";
        attributes[id].nftType = nftType;

        if (nftType == 1) {
            attributes[id].symbol = "METANOIA-SURNFT";
            attributes[id].name = "Metanoia Single-use Redeemable NFT";
            attributes[id].infiniteRedemptions = false;
            attributes[id].redemptions = 1;
        } else if (nftType == 2) {
            attributes[id].symbol = "METANOIA-MURNFT";
            attributes[id].name = "Metanoia Multi-use Redeemable NFT";
            attributes[id].infiniteRedemptions = false;
            attributes[id].redemptions = redemptions;
        } else if (nftType == 3) {
            attributes[id].symbol = "METANOIA-IRNFT";
            attributes[id].name = "Metanoia Infinitely Redeemable NFT";
            attributes[id].infiniteRedemptions = true;
            attributes[id].redemptions = 1;
        } else {
            revert("given nftType is not valid to set Attributes for.");
        }
    }

	function uri(uint256 nftId) override(ERC1155MultiUri) public view returns (string memory) {
		string memory json = Base64.encode(
			bytes(string(abi.encodePacked('{',
				'"name": "', attributes[nftId].name, '",',
				'"image": "', attributes[nftId].imageUri, '",',
				'"description": "', attributes[nftId].description, '",',
				'"attributes": [',
					'{"trait_type": "NFT Type", "value": ', 
                    uint2str(attributes[nftId].nftType), '},',
					'{"trait_type": "Infinite Redemptions", "value": ', 
                    bool2str(attributes[nftId].infiniteRedemptions), '},',
					'{"trait_type": "Redemptions", "value": ', 
                    uint2str(attributes[nftId].redemptions), '}',
				']}'
			)))
		);
		return string(abi.encodePacked('data:application/json;base64,', json));
	}  

	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function bool2str(bool _b) internal pure returns (string memory _boolAsString) {
		if (_b) {
			return "true";
		} else {
			return "false";
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