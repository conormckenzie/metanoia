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

// index tracking
import "./utils/Uint Lists.sol";

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

interface IDataSafeguardChecker {
    function isValidAttributeData(
        string memory attributeType, 
        string memory attributeName, 
        bytes memory attributeValue, 
        uint nftId
    ) external view returns (bool);
}

interface IUriProvider {
    function uri(uint nftId) external view returns (bool);
}

contract OnChainTestNft is 
    ERC1155Supply, 
    ERC2981ContractWideRoyalties, 
    Ownable,
    ReentrancyGuard, 
    EmergencyPausable,
    UintLists
{
    event contractUriChanged(address indexed msgSender, string indexed olduri, string indexed newuri);
    event royaltyInfoChanged(address indexed msgSender, address indexed recipient, uint indexed value);

    bytes32 public constant WRITE_ACCESS_AUTHORIZER_ROLE = keccak256("WRITE_ACCESS_AUTHORIZER_ROLE");
    bytes32 public constant WRITE_ACCESSOR_ROLE = keccak256("WRITE_ACCESSOR_ROLE");
    bytes32 public constant ATTRIBUTE_REGISTRAR_ROLE = keccak256("ATTRIBUTE_REGISTRAR_ROLE");
    // bytes32 public constant WRITE_META_ACCESSOR_ROLE = keccak256("WRITE_META_ACCESSOR_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    uint constant visibleInUriIndex = 1;

    // ALL testing flags should be FALSE when deploying
    bool constant testing1 = true; // toggles use of testing (true) or real (false) name, symbol, and contractUri.
    bool constant testing2 = true; // toggles use of testing (true) or real (false) description, image, and animation.

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public constant name = testing1 ? "Test Mixie" : "Mixie"; 
    string public constant symbol = testing1 ? "METANOIA MIXIE TEST" : "METANOIA MIXIE"; 

    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = testing1 ? "" : "https://ojpdoobn6gon7czwnz4cxf3hyfknkr6sd6j5ubs3ibwhtbpxwd6a.arweave.net/cl43OC3xnN-LNm54K5dnwVTVR9Ifk9oGW0BseYX3sPw";

    // points to a contract which handles custom or non-standard types 
    ICustomTypeHandler customTypeHandler;

    // points to a contract which handles safety checks for given data types
    IDataSafeguardChecker dataSafeguardChecker; 

    bool public forceChecked = true;
    bool public skipBrokenUriAttributes = true;

    



    // AttributeContext provides the name, variable type, and registration status 
    // for a given attribute in `attributes` or `attributeContexts` with the same numeric ID.
    struct AttributeContext {
        string attributeName;
        string attributeType;
        bool registered;
        bytes defaultValue;
    }

    struct AttributeContextList {
        AttributeContext[] context_fromID;
        mapping(string => uint) ID_fromName;
    }
    AttributeContextList attributeContexts;

    // offloaded - another contract will need to take care of this
    // AttributeContextList metaAttributeContexts;

    // maps NFT ID to the attribute list for that NFT
    mapping(uint => mapping(uint => bytes)) attributes;

    // offloaded - another contract will need to take care of this
    // // maps attribute ID to the metaAttribute list for that attribute
    // mapping(uint => mapping(uint => bytes)) metaAttributes;

    constructor() ERC1155("") {
        initialize();
    }

    function initialize() public virtual override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);
        
        // Register attribute 0 as a default "null" attribute
        attributeContexts.context_fromID.push(AttributeContext(
            "",
            "string",
            true,
            TypeConversions.StringToBytes("")
        ));
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "name",
            "string",
            TypeConversions.StringToBytes(testing1 ? "Test Mixie" : "Mixie")
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "description",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "test description" : "Metanoia is an alternative nation native to web3, where everyone will be able to gain access and own a slice of the power and economic opportunities previously only made available to the political elite, the well connected or the rich. \n\nThe Founding Citizen NFTs, represented in the form of Mixies, allows holders to get special perks and privileges from Metanoia. \nLearn more about Founding Citizen NFT benefits: https://medium.com/metanoia-country/founding-citizen-nft-sale-b7e1524a5e69")
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "image",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "" : "{TBD Arweave URL}")
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "external_link",
            "string",
            TypeConversions.StringToBytes("https://metanoia.country/")
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "fee_recipient",
            "address",
            TypeConversions.addressToBytes(0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d)
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        registerAttribute(
            "animation_url",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "" : "{TBD Arweave URL}")
        );
        setUriVisibility(attributeContexts.context_fromID.length - 1, true);
        super.initialize();
    }

    /** @notice Returns the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     */
    /// @dev    This method is separate from ERC2981 and does not use the on-chain variables that RoyaltyInfo uses.
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /** @dev    Sets the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     *          This method does NOT update the on-chain variables that ERC2981 uses. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called to change the OpenSea royalties, `setRoyaltyInfo(address, uint)` should also be called.
     */
    /// @param  newUri The new contract URI.
    function setContractUri(string calldata newUri) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        emit contractUriChanged(_msgSender(), _contractUri, newUri);
        _contractUri = newUri;
    }

    /** @dev    Sets the ERC2981 royalty info for the collection of tickets. 
     *          This method does NOT update the contractURI royalty values which are used by OpenSea. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called, `setContrctUri(string)` should also be called to point to a new metadata file which contains
     *          the updated royalty information.
     */
    /// @param  recipient The address which will receive royalty payments
    /// @param  feeInBasisPoints The royalty fee in basis points (units of 0.01%)
    function setRoyaltyInfo(address recipient, uint feeInBasisPoints) 
    public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        royaltyRecipient = recipient;
        royaltyFee = feeInBasisPoints;
        _setRoyalties(royaltyRecipient, royaltyFee);
        emit royaltyInfoChanged(_msgSender(), recipient, feeInBasisPoints);
    }

    function changeForcedCheck(bool _bool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        forceChecked = _bool;
    }

    function authorizeAddressForWritingAttributes(address _address, bool canRegisterNewAttributes) 
    external nonReentrant {
        require(
            hasRole(WRITE_ACCESS_AUTHORIZER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERRX"
            //"Sender is not authorized to grant write access to data"
        );
        // _addAddress(_address, authorizedAddressesIndex);
        _grantRole(WRITE_ACCESSOR_ROLE, _address);
        if (canRegisterNewAttributes) {
            _grantRole(ATTRIBUTE_REGISTRAR_ROLE, _address);
        }
    }

    function registerAttribute(
        string memory attributeName,
        string memory attributeType,
        bytes memory defaultValue
    ) public {
        require(
            hasRole(ATTRIBUTE_REGISTRAR_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERRX"
            // "Sender is not Attribute Registrar or Admin"
        );
        // 0. check that name has not already been registed
        // 1. push AttributeContext to attributeContexts.context_fromID[]
        // 2. map the attribute's name to ID in attributeContexts.ID_fromName

        require(
            attributeContexts.ID_fromName[attributeName] == 0,
            "ERRX"
            // an attribute with this name has already been registered 
        );
        attributeContexts.context_fromID.push(AttributeContext(
            attributeName,
            attributeType,
            true,
            defaultValue
        ));
        // attributeContexts.context_fromID is 1-indexed
        attributeContexts.ID_fromName[attributeName] = attributeContexts.context_fromID.length - 1;
    }

    // returns the registration status for an attribute of a given id
    function isRegistered(uint attributeId) public view returns(bool) {
        return attributeContexts.context_fromID[attributeId].registered;
    }

    function getAttributeIdFromName(string memory attributeName) public view returns(uint) {
        return attributeContexts.ID_fromName[attributeName];
    }

    // gets an attribute from `attributes`. If `checked` is true, will run checks from the dataSafeguardChecker
    // and require that the attribute is registered. 
    function getAttributeById(uint nftId_, uint attributeId, bool checked) public view returns(bytes memory) {
        if (checked) {
            if (address(dataSafeguardChecker) != address(0)) {
                require(
                    dataSafeguardChecker.isValidAttributeData(
                        attributeContexts.context_fromID[attributeId].attributeType, 
                        attributeContexts.context_fromID[attributeId].attributeName, 
                        attributes[nftId_][attributeId],
                        nftId_
                    ),
                    "ERRX"
                    // "data in `attributes[{nftId_}][{attributeId}] failed data checks`"
                );
            }
            require(isRegistered(attributeId));
        }
        return attributes[nftId_][attributeId];
    }

    function getAttribute(uint nftId_, string memory attributeName, bool checked) public view returns(bytes memory) {
        return getAttributeById(nftId_, getAttributeIdFromName(attributeName), checked);
    }

    function _setAttribute(uint nftId_, uint attributeId, bool checked, bytes memory value) internal {
        require(
            hasRole(WRITE_ACCESSOR_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERRX"
            // "Sender is not authorised to write and is not Admin"
        );
        if (checked || forceChecked) {
            if (address(dataSafeguardChecker) != address(0)) {
                require(
                    dataSafeguardChecker.isValidAttributeData(
                        attributeContexts.context_fromID[attributeId].attributeType, 
                        attributeContexts.context_fromID[attributeId].attributeName, 
                        value,
                        nftId_
                    ),
                    "ERRX"
                    // "given value failed data checks`"
                );
            }
            require(isRegistered(attributeId));
        }
        attributes[nftId_][attributeId] = value;
    }
    function setAttributeById(uint nftId_, uint attributeId, bool checked, bytes memory value)
    external nonReentrant {
        _setAttribute(nftId_, attributeId, checked, value);
    }

    function setAttribute(uint nftId_, string memory attributeName, bool checked, bytes memory value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, value);
    }

    function setUriVisibility(uint attributeId, bool visible) public {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERRX"
            // "Sender is not Uri Manager or Admin"
        );
        if (visible) {
            _tryToAddUint(attributeId, visibleInUriIndex);
        }
        else {
            _tryToRemoveUint(attributeId, visibleInUriIndex);
        }
    }

    

    // DEVNOTE: incomplete formatting - need to massage to fit into OpenSea's expected format
    // DEVNOTE: can condense?
    // Note:    This uri call is VERY expensive, and should NOT be used within a contract transaction.
    //          This is only for compatibility with ERC1155, intended to be called from off-blockchain applications
	function uri(uint256 nftId) override(ERC1155) public view returns (string memory) {
		// add each of the pre-existing required attributes into the uri
        string memory _uriString = string(abi.encodePacked('{',
            '"name": "', TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("name")]), '",',
            '"symbol": "', symbol,
            '"image": "', TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("image")]), '",',
            '"description": "', 
                TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("description")]), 
            '",'
        ));

        // if animation_url is not empty, add it into the uri 
        if (
            keccak256(abi.encodePacked(
                TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("animation_url")]) 
            ))
            == keccak256(abi.encodePacked(""))
        ) {
            _uriString = string(abi.encodePacked(
                _uriString,
                '"animation_url": "', 
                    TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("animation_url")]), 
                '",'
            ));
        }
        
        // setup for filling "attributes" in json uri
        _uriString = string(abi.encodePacked(
            _uriString,
            '"attributes": ['
        ));
        
        // loop over all registered attributes in the uintList `visibleInUri`
        for (uint _i = 0; _i < uintLists[1].length; _i++) {
            uint i = uintLists[1].list[_i];
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
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName,
                    '", "value": ',
                    TypeConversions.boolToString(TypeConversions.bytesToBool(attributes[nftId][i])),
                    '}'
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
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName, 
                    '", "value": ',
                    TypeConversions.uintToString(TypeConversions.bytesToUint(attributes[nftId][i])),
                    '}'
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
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName, 
                    '", "value": ',
                    TypeConversions.intToString(TypeConversions.bytesToInt(attributes[nftId][i])),
                    '}'
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
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName, 
                    '", "value": ',
                    TypeConversions.addressToString(TypeConversions.bytesToAddress(attributes[nftId][i])),
                    '}'
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
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName, 
                    '", "value": ',
                    TypeConversions.bytes32ToString(TypeConversions.bytesToBytes32(attributes[nftId][i])),
                    '}'
                ));
                matchedType = true;
            }

            // string
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bytes"))
            ) {
                // for strings, the value is encapsulated in an extra set of "" quotation marks  
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '{"trait_type": "',
                    attributeContexts.context_fromID[i].attributeName, 
                    '", "value": "',
                    TypeConversions.bytesToString(attributes[nftId][i]),
                    '"}'
                ));
                matchedType = true;
            }

            // custom types
            else if (address(customTypeHandler) != address(0)) { 
                // if a customTypeHandler does not exist, skip this step
                if (customTypeHandler.isKnownType(attributeContexts.context_fromID[i].attributeType)) {
                    // for custom types, the value is encapsulated in an extra set of "" quotation marks  
                    _uriString = string(abi.encodePacked(
                        _uriString, 
                        '{"trait_type": "', 
                        attributeContexts.context_fromID[i].attributeName, 
                        '", "value": "',
                        customTypeHandler.typeToString(
                            attributeContexts.context_fromID[i].attributeType, 
                            attributes[nftId][i]
                        ),
                        '"}'
                    ));
                    matchedType = true;
                } 
            }

            if (!skipBrokenUriAttributes) {
                require(
                    matchedType,
                    "listed type does not match with any known type"
                );
            }

            // if not the last attribute in uri, add a comma
            if(_i < uintLists[1].length - 1) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    ','
                ));
            }
        }
        
        // close the "attributes" section and close the uri
        _uriString = string(abi.encodePacked(
            _uriString, 
            ']}'
        ));
        
		return string(abi.encodePacked(
            'data:application/json;base64,', 
            Base64.encode(bytes(_uriString))
        ));
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

// LEGACY

    //  // attributes uri formatting
    // 	'{"trait_type": "NFT Type", "value": ', uintToString(attributes[nftId].nftType), '},',
    // 	'{"trait_type": "Infinite Redemptions", "value": ', boolToString(attributes[nftId].infiniteRedemptions), '},',
    // 	'{"trait_type": "Redemptions", "value": ', uintToString(attributes[nftId].redemptions), '}',

    //-----
        // string memory json = Base64.encode(
		// 	bytes(string(abi.encodePacked('{',
		// 		'"name": "', TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("name")]), '",',
        //         '"symbol": "', symbol,
		// 		'"image": "', TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("image")]), '",',
        //         // solhint-disable-next-line max-line-length
		// 		'"description": "', TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("description")]), '",'
		// 		// '"attributes": [',

		// 		// ']}'
		// 	)))
		// );

    // function isRegistered(uint attributeId /*, uint listIndex*/) public view returns(bool) {
    //     // if(listIndex == 1) {
    //         return attributeContexts.context_fromID[attributeId].registered;
    //     // }
    //     // else if (listIndex == 2) {
    //     //     return metaAttributeContexts.context_fromID[attributeId].registered;
    //     // }
    //     // else {
    //     //     revert("ERRX");
    //     //     // "invalid list index. Accepted values are '1' and '2'"
    //     // }
    // }

    // function authorizeAddressForWritingMetaAttributes(address _address) external nonReentrant {
    //     require(
    //         hasRole(WRITE_ACCESS_AUTHORIZER_ROLE, _msgSender()) || 
    //         hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
    //         "ERRX"
    //         //"Sender is not authorized to grant write access to data"
    //     );
    //     // _addAddress(_address, authorizedAddressesIndex);
    //     _grantRole(WRITE_META_ACCESSOR_ROLE, _address);
    // }

    // function setMetaAttribute (uint attributeId_, uint metaAttributeId, bool checked, bytes memory value) 
    // external nonReentrant {
    //     require(
    //         hasRole(WRITE_META_ACCESSOR_ROLE, _msgSender()) || 
    //         hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
    //         "ERRX"
    //         // "Sender is not authorised to write and is not Admin"
    //     );
    //     if (checked) {
    //         if (address(dataSafeguardChecker) != address(0)) {
    //             require(
    //                 dataSafeguardChecker.isValidMetaAttributeData(
    //                     attributeContexts.context_fromID[metaAttributeId].attributeType, 
    //                     attributeContexts.context_fromID[metaAttributeId].attributeName, 
    //                     value,
    //                     attributeId_
    //                 ),
    //                 "ERRX"
    //                 // "data in `metaAttributes[{attributeId_}][{metaAttributeId}] failed data checks`"
    //             );
    //         }
    //         require(isRegistered(metaAttributeId, 2));
    //     }
    //     metaAttributes[attributeId_][metaAttributeId] = value;
    // }

    // function getMetaAttribute (uint attributeId_, uint metaAttributeId, bool checked) 
    // public view returns(bytes memory) {
    //     if (checked) {
    //         if (address(dataSafeguardChecker) != address(0)) {
    //             require(
    //                 dataSafeguardChecker.isValidMetaAttributeData(
    //                     attributeContexts.context_fromID[metaAttributeId].attributeType, 
    //                     attributeContexts.context_fromID[metaAttributeId].attributeName, 
    //                     attributes[attributeId_][metaAttributeId],
    //                     attributeId_
    //                 ),
    //                 "ERRX"
    //                 // "data in `metaAttributes[{attributeId_}][{metaAttributeId}] failed data checks`"
    //             );
    //         }
    //         require(isRegistered(metaAttributeId, 2));
    //     }
    //     return metaAttributes[attributeId_][metaAttributeId];
    // }

}