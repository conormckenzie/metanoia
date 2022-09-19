// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EmergencyPausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ModeratedUris is EmergencyPausable {

    event approvedMetadataForId(address indexed msgSender, uint id, string metadata_uri);
    event approvedMetadataForAll(address indexed msgSender, string indexed metadata_uri);
    event unapprovedMetadataForId(address indexed msgSender, uint id, string indexed metadata_uri);
    event unapprovedMetadataForAll(address indexed msgSender, string indexed metadata_uri);
    event unapprovingAllMetadataForId(address indexed msgSender, uint id);
    event unapprovedAllMetadataForId(address indexed msgSender, uint id);

    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    bytes32 public constant URI_ADDER_ROLE = keccak256("URI_ADDER_ROLE");
    
    //replace with role to manage this.
    bool private canRevokeUriApproval;
    function makeApprovedUriListsAppendOnly() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        canRevokeUriApproval = false;
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
         * Usage: Returns a bool whether a given URI string is approved for a 
         *              given token id.
         */
        mapping(bytes32 => uint) indexWithIdUri;
        // bytes 32 = keccak256(abi.encodePacked(id, uri)) is the hash of the 
        // tuple (uint id, string uri)

        mapping(string => uint[]) indexesWithUri;

        mapping(uint => uint[]) indexesWithId;
    }
    State private _state;

    // LEVEL 0 functions: CRU(D) - encapsulate _state.entries

    function __entryExists(uint i) 
    private pure returns(bool) {
        return i != 0;
    }

    //create
    // warning: does not check if an existing entry with matching id and 
    // uri exists, as that is the domain of the next level
    function __makeEntry(uint _id, string memory _uri, bool _approved) 
    private returns(uint) {
        // entries[0] should always have id:0, uri:"", and approved:false
        if (_state.entries.length == 0) {
            _state.entries[0] = Entry({
                _entryID: 0,
                id: 0,
                uri: "",
                approved: false
            });
        }
        require(
            keccak256(bytes(_uri)) != keccak256(bytes("")),
            "ModeratedUris: ERR 1" 
            // "Cannot make entry with empty URI"
        );
        _state.entries.push(
            Entry({
                _entryID: _state.entries.length,
                id: _id,
                uri: _uri,
                approved: _approved
            })
        );
        return _state.entries.length-1; //returns the entryID of the new entry
    }

    //update
    function __updateEntry(uint i, bool _approved)
    private {
        require(i != 0, "ModeratedUris: ERR 2");
        // "Cannot edit _state.entries[0]"
        _state.entries[i].approved = _approved;
    }

    //retrieve - should be used in combination with L0:(exists) when it is not
    // okay to skip entries that don't exist
    function __getEntry(uint i, bool checked) 
    private view returns(Entry memory) {
        if (checked) {
            require(i != 0, "ModeratedUris: ERR 3");
            // "Cannot retrieve _state.entries[0]"
        }
        return _state.entries[i];
    }

    function __entryIsGlobal(uint i, bool checked)
    private view returns(bool) {
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

    // function _getAllUrisFromId(uint id, bool includeGloballyApproved) 
    // private view returns(string[] memory) {
    //     string[] memory results;
    //     if (includeGloballyApproved) {
    //         results = _getAllUrisFromId(0, false);
    //     }
    //     uint returnCount = results.length;
    //     for (uint count = 0; count < _state.indexesWithId[id].length; count++) {
    //         uint i = _state.indexesWithId[id][count];
    //         results[returnCount] = __getEntry(i, false).uri;
    //     }
    //     return results;
    // }

    function _getAllApprovedUrisFromId(uint id, bool includeGloballyApproved) 
    private view returns(string[] memory) {
        string[] memory results;
        if (includeGloballyApproved) {
            results = _getAllApprovedUrisFromId(0, false);
        }
        uint returnCount = results.length;
        for (uint count = 0; count < _state.indexesWithId[id].length; count++) {
            uint i = _state.indexesWithId[id][count];
            Entry memory e = __getEntry(i, false);
            if (e.approved) {
                results[returnCount] = e.uri;
                returnCount++;
            }
        }
        return results;
    }

    // function _getAllIdsFromUri(string memory uri, bool includeGloballyApproved) 
    // private view returns(uint[] memory) {
    //     uint[] memory results;
    //     if (includeGloballyApproved && _entryExists(0, uri)) {
    //         results[0] = __getEntry(0, false).id;
    //     }
    //     uint returnCount = results.length;
    //     for (uint count = 0; count < _state.indexesWithUri[uri].length; count++)
    //     {
    //         uint i = _state.indexesWithUri[uri][count];
    //         results[returnCount] = __getEntry(i, false).id;
    //     }
    //     return results;
    // }

    function _getAllApprovedIdsFromUri(
        string memory uri, 
        bool includeGloballyApproved
    ) private view returns(uint[] memory) {
        uint[] memory results;
        if (
            includeGloballyApproved && 
            _entryExists(0, uri) &&
            _getEntry(0, uri, true).approved
        ) {
            results[0] = 0;
        }
        uint returnCount = results.length;
        for (uint count = 0; count < _state.indexesWithUri[uri].length; count++) {
            uint i = _state.indexesWithUri[uri][count];
            Entry memory e = __getEntry(i, false);
            if (e.approved) {
                results[returnCount] = e.id;
                returnCount++;
            }
        }
        return results;
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

    function getAllGloballyApprovedMetadata() 
    public view returns(string[] memory) {
        return _getAllApprovedUrisFromId(0, false);
    }

    function getAllApprovedMetadatasForId(uint id, bool includeGloballyApproved) 
    public view returns(string[] memory) {
        if (id == 0) {
            return _getAllApprovedUrisFromId(0, false);
        } else {
            return _getAllApprovedUrisFromId(id, includeGloballyApproved);
        }
    }

    function getAllApprovedIdsForMetadata(string memory metadata_uri) 
    public view returns(uint[] memory) {
        return _getAllApprovedIdsFromUri(metadata_uri, true);
    }

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

    function initialize() public virtual override {
        super.initialize();
    }
}