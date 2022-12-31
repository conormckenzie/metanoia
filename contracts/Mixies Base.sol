// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ERC1155 & marketplace compatibility
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EmergencyPausable.sol";

// type conversions
import "./utils/TypeConversions.sol";

// uri encoding
import "./utils/Base64.sol";

// index tracking
import "./utils/Uint Lists.sol";



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

// ERROR - using an external uri provider was not properly implemented in this contract
interface IUriProvider {
    // function uri(uint nftId) external view returns (bool); // ERRONEOUS FUNCTION
    function uri(uint nftId) external view returns (bool); // NOT in live contract - added after deployment
}

contract MixiesBaseV1_0 is 
    ERC1155Supply, 
    ERC1155Holder,
    ERC2981ContractWideRoyalties, 
    Ownable,
    ReentrancyGuard, 
    EmergencyPausable,
    UintLists
{
    // ERROR CODES:
    // ERR1:    "Sender is not authorized to grant write access to data"
    // ERR2:    "Sender is not Attribute Registrar or Admin"
    // ERR3:    "An attribute with this name has already been registered" 
    // ERR4:    "Data in `attributes[{nftId_}][{attributeId}] failed data checks`"
    // ERR4A:   "Given value failed data checks"
    // ERR5:    "Sender is not authorised to write and is not Admin"
    // ERR6:    "Sender is not Uri Manager or Admin"
    // ERR7:    "Listed type does not match with any known type"
    // ERR8:    "Sender is not Hatch Manager or Admin"
    // ERR9:    "This contract only accepts NFTs produced from the mixie egg contract"
    // ERR9A:   "This Mixie egg cannot be hatched at this time"


    event contractUriChanged(address indexed msgSender, string indexed olduri, string indexed newuri);
    event royaltyInfoChanged(address indexed msgSender, address indexed recipient, uint indexed value);
    event forceCheckedChanged(address indexed msgSender, bool indexed oldValue, bool indexed newValue);
    event addressAuthorizedForWritingAttributes(
        address indexed msgSender, 
        address indexed authorizedAddress, 
        bool indexed canRegisterNewAttributes
    );
    event attributeRegistered(
        address indexed msgSender, 
        string indexed attributeName, 
        string indexed attributeType, 
        bytes defaultValue
    );
    event attributeSet(
        address indexed msgSender,
        uint indexed nftId_, 
        uint attributeId, 
        bool checked, 
        bytes indexed value
    );
    event uriVisibilitySet(address indexed msgSender, uint indexed attributeId, bool indexed visible);
    event hatchingAllowedSet(address indexed msgSender, uint indexed id, bool indexed value);
    event mixieEggReceived(address indexed operator, address indexed from, uint indexed id, uint value, bytes data);
    event dataSafeguardCheckerChanged(
        address indexed msgSender, 
        address indexed oldChecker, 
        address indexed newChecker
    );
    event customTypeHandlerChanged(
        address indexed msgSender, 
        address indexed oldHandler, 
        address indexed newHandler
    );


    bytes32 public constant WRITE_ACCESS_AUTHORIZER_ROLE = keccak256("1");
    bytes32 public constant WRITE_ACCESSOR_ROLE = keccak256("2");
    bytes32 public constant ATTRIBUTE_REGISTRAR_ROLE = keccak256("3");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("4");
    bytes32 public constant HATCH_MANAGER_ROLE = keccak256("5");

    uint constant visibleInUriIndex = 1;

    // ALL testing flags should be FALSE when deploying
    bool constant testing1 = false; // toggles use of testing (true) or real (false) name, symbol, and contractUri.
    bool constant testing2 = false; // toggles use of testing (true) or real (false) description, image, and animation.
    bool constant testing3 = false; // toggles use of testing (true) or real (false) Mixie egg contract.

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    // string public constant name = "Tst Mixie";
    string public constant name = "Mixie"; 
    // string public constant symbol = "METANOIA MIXIE Tst"
    string public constant symbol = "METANOIA MIXIE"; 

    address public constant mixieEggSenderContract = // testing3 ? 
    // 0xCb016e537e5FaA8F03A81461a2Ee1916e0d0c738: // testing egg contract on testnet
    // 0x15c53BA992849aB5291752F5dd373d964635FF03: // testing egg contract on mainnet
    0x6285333d3224D8fA5AD2146aF919225042F40d3b; // REAL egg contract on mainnet

    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    string _contractUri;

    // points to a contract which handles custom or non-standard types 
    ICustomTypeHandler customTypeHandler;

    // points to a contract which handles safety checks for given data types
    IDataSafeguardChecker dataSafeguardChecker; 

    bool public forceChecked = true;
    // bool public skipBrokenUriAttributes = true;

    // if `hatchingAllowed[0]` is true then all eggs are allowed to hatch,
    // else an egg with id `ID` is only allowed to hatch if `hatchingAllowed[ID]` is true
    mapping(uint => bool) public hatchingAllowed; 

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

    // for each NFT ID, for each attribute, tracks whether to treat blank as default value (false) or literal (true)
    mapping(uint => mapping(uint => bool)) treatBlankLiterally;

    // offloaded - another contract will need to take care of this
    // // maps attribute ID to the metaAttribute list for that attribute
    // mapping(uint => mapping(uint => bytes)) metaAttributes;

    constructor() ERC1155("") {
        initialize();
    }

    function initialize() public virtual override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);
        hatchingAllowed[0] = true;

        if (testing1) {
            // solhint-disable-next-line max-line-length
            _contractUri = "https://g4kxt42j3axbuh4zuif4fdlcinjueo2q7ns2arareajwmpuneb3q.arweave.net/NxV580nYLhofmaILwo1iQ1NCO1D7ZaBEESATZj6NIHc";
            assert(keccak256(bytes(name)) == keccak256(bytes("Tst Mixie")));
            assert(keccak256(bytes(symbol)) == keccak256(bytes("METANOIA MIXIE Tst")));
        }
        else {
            _contractUri = ""; // can be added post-launch
            assert(keccak256(bytes(name)) == keccak256(bytes("Mixie")));
            assert(keccak256(bytes(symbol)) == keccak256(bytes("METANOIA MIXIE")));
        }

        if (testing3) {
            assert(mixieEggSenderContract == 0x15c53BA992849aB5291752F5dd373d964635FF03);
        }
        else {
            assert(mixieEggSenderContract == 0x6285333d3224D8fA5AD2146aF919225042F40d3b);
        }
        
        // Register attribute 0 as a default "null" attribute
        attributeContexts.context_fromID.push(AttributeContext(
            "",
            "string",
            true,
            TypeConversions.stringToBytes("")
        ));
        setUriVisibility(attributeContexts.context_fromID.length - 1, false);

        // utilizes a setup script that allows setting all the initial conditions

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

    function setDataSafeguardChecker(address _dataSafeguardChecker) 
    external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        emit dataSafeguardCheckerChanged(msg.sender, address(dataSafeguardChecker), _dataSafeguardChecker);
        dataSafeguardChecker = IDataSafeguardChecker(_dataSafeguardChecker);
    }

    function setCustomTypeHandler(address _customTypeHandler) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        emit customTypeHandlerChanged(msg.sender, address(customTypeHandler), _customTypeHandler);
        customTypeHandler = ICustomTypeHandler(_customTypeHandler);
    }

    function setHatchingAllowed(uint id, bool value) public whenNotPaused {
        require(
            hasRole(HATCH_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR8"
            // "Sender is not Hatch Manager or Admin"
        );
        hatchingAllowed[id] = value;
        emit hatchingAllowedSet(msg.sender, id, value);
    }

    function changeForceChecked(bool _bool) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        emit forceCheckedChanged(msg.sender, forceChecked, _bool);
        forceChecked = _bool;
    }

    function authorizeAddressForWritingAttributes(address _address, bool canRegisterNewAttributes) 
    external nonReentrant whenNotPaused {
        require(
            hasRole(WRITE_ACCESS_AUTHORIZER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR1"
            //"Sender is not authorized to grant write access to data"
        );
        _grantRole(WRITE_ACCESSOR_ROLE, _address);
        if (canRegisterNewAttributes) {
            _grantRole(ATTRIBUTE_REGISTRAR_ROLE, _address);
        }
        emit addressAuthorizedForWritingAttributes(msg.sender, _address, canRegisterNewAttributes);
    }

    function registerAttribute(
        string memory attributeName,
        string memory attributeType,
        bytes memory defaultValue
    ) public whenNotPaused {
        require(
            hasRole(ATTRIBUTE_REGISTRAR_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR2"
            // "Sender is not Attribute Registrar or Admin"
        );
        // 0. check that name has not already been registed
        // 1. push AttributeContext to attributeContexts.context_fromID[]
        // 2. map the attribute's name to ID in attributeContexts.ID_fromName

        require(
            attributeContexts.ID_fromName[attributeName] == 0,
            "ERR3"
            // "An attribute with this name has already been registered" 
        );
        attributeContexts.context_fromID.push(AttributeContext(
            attributeName,
            attributeType,
            true,
            defaultValue
        ));
        // attributeContexts.context_fromID is 1-indexed
        attributeContexts.ID_fromName[attributeName] = attributeContexts.context_fromID.length - 1;
        emit attributeRegistered(msg.sender, attributeName, attributeType, defaultValue);
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
    function getAttributeById(uint nftId_, uint attributeId, bool checked, bool blankIsDefault) 
    public view returns(bytes memory) {
        if (checked) {
            if (address(dataSafeguardChecker) != address(0)) {
                require(
                    dataSafeguardChecker.isValidAttributeData(
                        attributeContexts.context_fromID[attributeId].attributeType, 
                        attributeContexts.context_fromID[attributeId].attributeName, 
                        attributes[nftId_][attributeId],
                        nftId_
                    ),
                    "ERR4"
                    // "Data in `attributes[{nftId_}][{attributeId}] failed data checks`"
                );
            }
            require(isRegistered(attributeId));
        }
        if (blankIsDefault && keccak256(attributes[nftId_][attributeId]) == keccak256("")) {
            return attributeContexts.context_fromID[attributeId].defaultValue;
        }
        return attributes[nftId_][attributeId];
    }

    function getAttribute(uint nftId_, string memory attributeName, bool checked, bool blankIsDefault) 
    public view returns(bytes memory) {
        return getAttributeById(nftId_, getAttributeIdFromName(attributeName), checked, blankIsDefault);
    }

    function _setAttribute(uint nftId_, uint attributeId, bool checked, bytes memory value) internal whenNotPaused {
        require(
            hasRole(WRITE_ACCESSOR_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR5"
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
                    "ERR4A"
                    // "Given value failed data checks"
                );
            }
            require(isRegistered(attributeId));
        }
        attributes[nftId_][attributeId] = value;
        emit attributeSet(msg.sender, nftId_, attributeId, checked, value);
    }
    function setAttributeById(uint nftId_, uint attributeId, bool checked, bytes memory value)
    external nonReentrant {
        _setAttribute(nftId_, attributeId, checked, value);
    }

    function setAttribute(uint nftId_, string memory attributeName, bool checked, bytes memory value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, value);
    }

    function setBoolAttribute(uint nftId_, string memory attributeName, bool checked, bool value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.boolToBytes(value));
    }

    function setUintAttribute(uint nftId_, string memory attributeName, bool checked, uint value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.uintToBytes(value));
    }

    function setIntAttribute(uint nftId_, string memory attributeName, bool checked, int value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.intToBytes(value));
    }

    function setAddressAttribute(uint nftId_, string memory attributeName, bool checked, address value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.addressToBytes(value));
    }

    function setBytes32Attribute(uint nftId_, string memory attributeName, bool checked, bytes32 value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.bytes32ToBytes(value));
    }

    function setStringAttribute(uint nftId_, string memory attributeName, bool checked, string memory value) 
    external nonReentrant {
        _setAttribute(nftId_, getAttributeIdFromName(attributeName), checked, TypeConversions.stringToBytes(value));
    }

    function setUriVisibility(uint attributeId, bool visible) public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR6"
            // "Sender is not Uri Manager or Admin"
        );
        if (visible) {
            _tryToAddUint(attributeId, visibleInUriIndex);
        }
        else {
            _tryToRemoveUint(attributeId, visibleInUriIndex);
        }
        emit uriVisibilitySet(msg.sender, attributeId, visible);
    }

    // Note:    This uri call can be VERY expensive, and should generally NOT be used within a contract transaction.
    //          This is only for compatibility with ERC1155, intended to be called from off-blockchain applications
	function uri(uint256 nftId) override(ERC1155) public view returns (string memory) {
		// add each of the pre-existing required attributes into the uri
        string memory _uriString = string(abi.encodePacked('{\n\t',
            '"name":"', 
                TypeConversions.bytesToString(getAttribute(nftId, "name", false, true)), 
            '",\n\t',
            '"symbol":"', 
                symbol, 
            '",\n\t',
            '"image":"', 
                TypeConversions.bytesToString(getAttribute(nftId, "image", false, true)), 
            '",\n\t',
            '"description":"', 
                // TypeConversions.bytesToString(attributes[nftId][getAttributeIdFromName("description")]), 
                TypeConversions.bytesToString(getAttribute(nftId, "description", false, true)), 
            '",\n\t',
            '"external_url":"', 
            TypeConversions.bytesToString(getAttribute(nftId, "external_url", false, true)), 
            '",\n\t'
        ));

        // if animation_url is not empty, add it into the uri 
        if (
            keccak256(abi.encodePacked(
                TypeConversions.bytesToString(getAttribute(nftId, "animation_url", false, true)) 
            ))
            != keccak256(abi.encodePacked(""))
        ) {
            _uriString = string(abi.encodePacked(
                _uriString,
                '"animation_url": "', 
                    TypeConversions.bytesToString(getAttribute(nftId, "animation_url", false, true)), 
                '",\n\t'
            ));
        }
        
        // setup for filling "attributes" in json uri
        _uriString = string(abi.encodePacked(
            _uriString,
            '"attributes": ['
        ));
        
        // loop over all registered attributes in the uintList `visibleInUri`
        // first 5 present in uri (i=1...5) are listed outside the "attributes" section
        for (uint _i = 6; _i <= uintLists[1].length; _i++) { // change to 6
            uint i = uintLists[1].list[_i];
            // bool matchedType;
            // for each attribute, if the value of that attribute for that ID is not the default value,
            // then add the NAME and VALUE (converted from bytes to the attribute's TYPE then to string)

            // bool
            if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bool"))
            ) {
				
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.boolToString(TypeConversions.bytesToBool(getAttributeById(nftId, i, false, true))),
                    '"\n\t\t}'
                ));
                // matchedType = true;
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
                    '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.uintToString(TypeConversions.bytesToUint(getAttributeById(nftId, i, false, true))),
                    '"\n\t\t}'
                ));
                // matchedType = true;
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
                    '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.intToString(TypeConversions.bytesToInt(getAttributeById(nftId, i, false, true))),
                    '"\n\t\t}'
                ));
                // matchedType = true;
            }

            // address
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("address"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                   '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.addressToString(TypeConversions.bytesToAddress(
                        getAttributeById(nftId, i, false, true)
                    )),
                    '"\n\t\t}'
                ));
                // matchedType = true;
            }

            // bytes32
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bytes32"))
            ) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.bytes32ToString(TypeConversions.bytesToBytes32(
                        getAttributeById(nftId, i, false, true)
                    )),
                    '"\n\t\t}'
                ));
                // matchedType = true;
            }

            // bytes or string
            else if (
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("bytes")) || 
                keccak256(abi.encodePacked(attributeContexts.context_fromID[i].attributeType)) ==
                keccak256(abi.encodePacked("string"))
            ) {
                // for strings, the value is encapsulated in an extra set of "" quotation marks  
                _uriString = string(abi.encodePacked(
                    _uriString, 
                   '\n\t\t{',
                    '\n\t\t\t"trait_type":"',
                    attributeContexts.context_fromID[i].attributeName,
                    '",',
                    '\n\t\t\t"value":"',
                    TypeConversions.bytesToString(getAttributeById(nftId, i, false, true)),
                    '"\n\t\t}'
                ));
                // matchedType = true;
            }

            // custom types
            else if (address(customTypeHandler) != address(0)) { 
                // if a customTypeHandler does not exist, skip this step
                if (customTypeHandler.isKnownType(attributeContexts.context_fromID[i].attributeType)) {
                    // for custom types, the value is encapsulated in an extra set of "" quotation marks  
                    _uriString = string(abi.encodePacked(
                        _uriString, 
                        '\n\t\t{',
                        '\n\t\t\t"trait_type":"',
                        attributeContexts.context_fromID[i].attributeName,
                        '",',
                        '\n\t\t\t"value":"',
                        customTypeHandler.typeToString(
                            attributeContexts.context_fromID[i].attributeType, 
                            getAttributeById(nftId, i, false, true)
                        ),
                        '"\n\t\t}'
                    ));
                    // matchedType = true;
                } 
            }

            // if (!skipBrokenUriAttributes) {
            //     require(
            //         matchedType,
            //         "ERR7"
            //         // "Listed type does not match with any known type"
            //     );
            // }

            // if not the last attribute in uri and the attribute is not skipped, add a comma
            if(_i < uintLists[1].length /*&& matchedType*/) {
                _uriString = string(abi.encodePacked(
                    _uriString, 
                    ','
                ));
            }
        }
        
        // close the "attributes" section and close the uri
        _uriString = string(abi.encodePacked(
            _uriString, 
            '\n\t]\n}' // for use with attributes
            // '}' //for use without attributes (testing)
        ));
        
		return string(abi.encodePacked(
            'data:application/json;base64,', 
            Base64.encode(bytes(_uriString))
        ));
	}  

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(
            msg.sender == mixieEggSenderContract,
            "ERR9"
            // "This contract only accepts NFTs produced from the mixie egg contract"    
        );
        require(
            hatchingAllowed[0] || hatchingAllowed[id],
            "ERR9A"
            // "This Mixie egg cannot be hatched at this time"
        );
        _mint(from, id, value, data);
        emit mixieEggReceived(operator, from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes memory data
    ) public virtual override returns (bytes4) {
        // converts batch to serial processing
        for (uint i = 0; i < ids.length; i++ ) {
            onERC1155Received(operator, from, ids[i], values[i], data);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver, ERC2981Base, AccessControl)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }

}