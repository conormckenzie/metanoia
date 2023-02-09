//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// WARNING: Access control has been disabled for this proof of concept.

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/libraries/Base64.sol";

contract ERC1155CreatorV2_0 is ERC1155MultiUri {
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
    
    constructor() ERC1155(
    // solhint-disable-next-line max-line-length
        "https://5onxwdchjdxmgedt32sk5viwzfqxhhsycntmfoqiowaswrblkt7a.arweave.net/65t7DEdI7sMQc96krtUWyWFznlgTZsK6CHWBK0QrVP4"
    ) {

        name = "Metanoia NFT";
        symbol = "METANOIA-NFT";

        // 1: single-use redeemable NFT
        // 2: multi-use redeemable NFT
        // 3: infinitely redeemable NFT
        uriList[1] = "single-use";
        uriList[2] = "multi-use";
        uriList[3] = "infinite-use";
    }

    function mintNewTicketCollection(address to, uint amount, uint nftType) public /*onlyOwner*/ returns(uint) {
        require(nftType >= 1 && nftType <= 3, "NFT type must be between 1 and 3");
        require(!(nftType == 3 && amount > 1),"An NFT of type 3 must be unique");
        nextTokenID++;
        totalSupply += amount;
        _mintWithAttributes(to, nextTokenID-1, amount, "", uriList[nftType], nftType);
        return nextTokenID-1;
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
        attributes[id].description = 
        // solhint-disable-next-line max-line-length
            "A ticket given to the first ever 100 settlers to set foot on Metanoia. It is rumoured that the original owners had to make extreme sacrifices to obtain them, and that the holders of these tickets might have unknown, but pleasant surprises that await them in the future.";
        attributes[id].imageUri = 
        // solhint-disable-next-line max-line-length
            "https://5onxwdchjdxmgedt32sk5viwzfqxhhsycntmfoqiowaswrblkt7a.arweave.net/65t7DEdI7sMQc96krtUWyWFznlgTZsK6CHWBK0QrVP4";
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