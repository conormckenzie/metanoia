// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EmergencyPausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract ModeratedUris is EmergencyPausable {

    event approvedMetadataForId(address indexed msgSender, uint indexed id, string metadata_uri);
    event approvedMetadataForAll(address indexed msgSender, string indexed metadata_uri);
    event unapprovedMetadataForId(address indexed msgSender, uint indexed id, string indexed metadata_uri);
    event unapprovedMetadataForAll(address indexed msgSender, string indexed metadata_uri);
    event unapprovingAllMetadataForId(address indexed msgSender, uint indexed id);
    event unapprovedAllMetadataForId(address indexed msgSender, uint indexed id);
    event view_metadataIsApprovedForId(address indexed msgSender, uint indexed id, string indexed metadata_uri);

    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    bytes32 public constant URI_ADDER_ROLE = keccak256("URI_ADDER_ROLE");

    bool public debugMode_ModeratedUris;

    function initialize() public virtual override {
        // console.log("ModeratedUris: initializer");
        _state.entries.push(Entry({
            _entryID: 0,
            id: 0,
            uri: "",
            approved: false
        }));
        // bytesToRoles["URI_MANAGER_ROLE"] = URI_MANAGER_ROLE;
        // bytesToRoles["URI_ADDER_ROLE"] = URI_ADDER_ROLE;
        debugMode_ModeratedUris = false;
        super.initialize();
    }
    
    function setDebugMode(bool mode) external onlyRole(DEFAULT_ADMIN_ROLE) {
        debugMode_ModeratedUris = mode;
    } 

    modifier Entries_NoOOBArrayAccess(uint i) {
        require(i < _state.entries.length);
        _;
    }

    modifier ifDebugModeActive {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(debugMode_ModeratedUris, "ModeratedUris: debug mode is not active and caller is not admin");
        }
        _;
    }

    struct Entry {
        uint _entryID;

        uint id;
        //id = 0 means it applies to all ids
        string uri;
        bool approved;
    }

    struct State {
        /* 
         * @dev Stores the URIs that are approved for any NFT in the collection  
         *      to link to.
         *
         * Syntax:      gloabl[string]
         * Description: stores whether a given string is a globally approved URI.           
         */
        //mapping(string => bool) globalApproved;

        Entry[] entries; // (append/modify)-only
        
        /*  
         * @dev Stores the entry of the index for each (URI, ID) pair.
         *
         * Syntax:      indexWithIdUri[keccak256(abi.encodePacked(id, uri))]
         */
        mapping(bytes32 => uint) indexWithIdUri;
        // bytes 32 = keccak256(abi.encodePacked(id, uri)) is the hash of the 
        // tuple (uint id, string uri)

        // provides potential missing ids when only the uri is provided
        mapping(string => uint[]) indexesWithUri;

        // provides potential missing uris when only the id is provided
        mapping(uint => uint[]) indexesWithId;
    }
    State private _state;

    function get_bytes32hash(uint id, string memory uri) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(id, uri));
    }

    // admin-only testing functions

    function debug_get_entry(uint _entryId)
    external view Entries_NoOOBArrayAccess(_entryId) ifDebugModeActive 
    returns(uint _entryID, uint id, string memory uri, bool approved) {
        return (
            _state.entries[_entryId]._entryID,
            _state.entries[_entryId].id,
            _state.entries[_entryId].uri,
            _state.entries[_entryId].approved
        );
    }

    function debug_get_entries_length() 
    external view ifDebugModeActive returns(uint) {
        return _state.entries.length;
    }

    function debug_get_indexWithIdUri(bytes32 _bytes32) 
    external view ifDebugModeActive returns(uint) {
        return _state.indexWithIdUri[_bytes32];
    }

    function debug_get_indexesWithUri(string memory _string, uint _indexId) 
    external view ifDebugModeActive returns(uint) {
        return _state.indexesWithUri[_string][_indexId];
    }

    function debug_get_indexesWithUri_length(string memory _string)
    external view ifDebugModeActive returns(uint) {
        return _state.indexesWithUri[_string].length;
    }

    function debug_get_indexesWithId(uint id, uint _indexId) 
    external view ifDebugModeActive returns(uint) {
        return _state.indexesWithId[id][_indexId];
    }

    function debug_get_indexesWithId_length(uint id)
    external view ifDebugModeActive returns(uint) {
        return _state.indexesWithId[id].length;
    }

    // LEVEL 0 functions: CRU(D) - encapsulate _state.entries

    function __entryExists(uint i) 
    private view Entries_NoOOBArrayAccess(i) returns(bool) {
        return i != 0;
    }

    //create
    // warning: does not check if an existing entry with matching id and 
    // uri exists, as that is the domain of the next level
    function __makeEntry(uint _id, string memory _uri, bool _approved) 
    private returns(uint) {
        // entries[0] should always have id:0, uri:"", and approved:false
        if (_state.entries.length == 0) {
            _state.entries.push(Entry({
                _entryID: 0,
                id: 0,
                uri: "",
                approved: false
            }));
        }
        require(
            keccak256(bytes(_uri)) != keccak256(bytes("")),
            "ModeratedUris: ERR 1" 
            // "Cannot make entry with empty URI"
        );
        _state.entries.push(Entry({
            _entryID: _state.entries.length,
            id: _id,
            uri: _uri,
            approved: _approved
        }));
        return _state.entries.length-1; //returns the entryID of the new entry
    }

    //update
    function __updateEntry(uint i, bool _approved)
    private Entries_NoOOBArrayAccess(i) {
        require(i != 0, "ModeratedUris: ERR 2");
        // "Cannot edit _state.entries[0]"
        _state.entries[i].approved = _approved;
    }

    //retrieve - should be used in combination with L0:(exists) when it is not
    // okay to skip entries that don't exist
    function __getEntry(uint i, bool checked) 
    private view Entries_NoOOBArrayAccess(i) returns(Entry memory) {
        if (checked) {
            require(i != 0, "ModeratedUris: ERR 3");
            // "Cannot retrieve _state.entries[0]"
        }
        return _state.entries[i];
    }

    function __entryIsGlobal(uint i, bool checked)
    private view Entries_NoOOBArrayAccess(i) returns(bool) {
        return __getEntry(i, checked).id == 0;
    }

    // LEVEL 1 functions: link _state variables to encapsulate entryId member
    
    //(exists)
    function _entryExists(uint id, string memory uri)
    private view returns(bool) {
        uint i = _state.indexWithIdUri[keccak256(abi.encodePacked(id, uri))];
        return __entryExists(i);
    }

    function _entryIsGlobal(uint id, string memory uri, bool checked)
    private view returns(bool) {
        uint i = _state.indexWithIdUri[keccak256(abi.encodePacked(id, uri))];
        return __entryIsGlobal(i, checked);
    }

    function _getEntry(uint id, string memory uri, bool checked) 
    private view returns(Entry memory) {
        uint i = _state.indexWithIdUri[keccak256(abi.encodePacked(id, uri))];
        return __getEntry(i, checked);
    }

    function _makeEntry(uint id, string memory uri, bool approved) 
    private {
        require(
            !_entryExists(id, uri), 
            "L1: _makeEntry: entry with matching id and uri already exists"
        );
        uint i = __makeEntry(id, uri, approved);
        _state.indexWithIdUri[keccak256(abi.encodePacked(id, uri))] = i;
        _state.indexesWithId[id].push(i);
        _state.indexesWithUri[uri].push(i);
    }

    function _updateEntry(uint id, string memory uri, bool approved) 
    private {
        uint i = _state.indexWithIdUri[keccak256(abi.encodePacked(id, uri))];
        __updateEntry(i, approved);
    }

    function _isIdUriPairApproved(uint id, string memory uri)
    private view returns(bool) {
        return _getEntry(id, uri, false).approved;
    }

    function _unapproveUriForAllIds(
        string memory uri, 
        bool includeGloballyApproved
    ) private {
        for (uint count = 0; count < _state.indexesWithUri[uri].length; count++) {
            uint i = _state.indexesWithUri[uri][count];
            if (includeGloballyApproved || !__entryIsGlobal(i, true)) {
                __updateEntry(i, false);
            } 
        }
    }

    function _unapproveAllUrisForId(uint id) 
    private {
        for (uint count = 0; count < _state.indexesWithId[id].length; count++) {
            uint i = _state.indexesWithId[id][count];
            __updateEntry(i, false);
            emit unapprovedMetadataForId(_msgSender(), id, __getEntry(i, false).uri);
        }
    }

    // LEVEL 2 functions: public-facing and helper functions

    /*  
     * @dev Approves a URI to be used globally (id = 0) or for a specific token 
     *      ID.
     */
    function _setIdUriPairApproval(uint id, string memory uri, bool approved) 
    private {
        if (!_entryExists(id, uri)) { 
            _makeEntry(id, uri, approved);
        }
        else { 
            _updateEntry(id, uri, approved);
        }
    }


    function isMetadataApprovedForId(uint id, string memory metadata_uri) 
    public view returns(bool) {
        if (!_entryExists(id, metadata_uri)) { 
            return _isIdUriPairApproved(0, metadata_uri);
        } else {
            return 
                _isIdUriPairApproved(id, metadata_uri) || 
                _isIdUriPairApproved(0, metadata_uri)
            ;
        }
    }

    function isMetadataApprovedForAll(string memory metadata_uri)
    public view returns(bool) {
        return _isIdUriPairApproved(0, metadata_uri);
    }

    // // due to solidity limitations with dynamic arrays in memory, 
    // // providing all uris approved for an id or global use is infeasible, 
    // // and providing all ids a uri is approved for is also infeasible.

    // // if either of these features are needed, debug mode should be enabled to get the raw entries

    // does nothing if (0, uri) pair is already approved
    function approveMetadataForId(uint id, string memory metadata_uri) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(URI_ADDER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        _setIdUriPairApproval(id, metadata_uri, true);
        emit approvedMetadataForId(_msgSender(), id, metadata_uri);
    }

    // does nothing if (0, uri) pair is already approved
    function approveMetadataForAll(string memory metadata_uri) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(URI_ADDER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        _setIdUriPairApproval(0, metadata_uri, true);
        emit approvedMetadataForAll(_msgSender(), metadata_uri);
    }

    // does nothing if (id, uri) pair is already unapproved
    function unapproveMetadataForId(uint id, string memory metadata_uri) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        _setIdUriPairApproval(id, metadata_uri, false);
        emit unapprovedMetadataForId(_msgSender(), id, metadata_uri);
    }

    // does nothing if uri is already unapproved for all ids (including 0)
    function unapproveMetadataForAll(string memory metadata_uri) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        _unapproveUriForAllIds(metadata_uri, true);
        emit approvedMetadataForAll(_msgSender(), metadata_uri);
    }

    // does nothing if all uris for id are already unapproved
    // does not apply to globally approved uri
    function unapproveAllMetadataForId(uint id) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        emit unapprovingAllMetadataForId(_msgSender(), id);
        _unapproveAllUrisForId(id);
        emit unapprovedAllMetadataForId(_msgSender(), id);
    }
}