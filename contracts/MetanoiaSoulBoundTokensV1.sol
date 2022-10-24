// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EmergencyPausable.sol";

contract SoulBoundTokenV1 is ERC1155MultiUri, AccessControl, Ownable, EmergencyPausable {

    event uriLocked(address indexed msgSender, uint indexed id, string indexed lockedUri);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    uint public nextUnusedToken;
    mapping (uint => bool) public lockedUris;
    string public _contractUri;

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public name;
    string public symbol;

    constructor() ERC1155("") {
        initialize();
    }

    function initialize() public virtual override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_MANAGER_ROLE, msg.sender);
        name = "Metanoia Event Attendance Soul-Bound Token";
        symbol = "METANOIA POAP SBT";
        super.initialize();
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractUri(string memory contractUri) public onlyRole(URI_MANAGER_ROLE) whenNotPaused {
        emit uriChanged(_msgSender(), 0, _contractUri, contractUri);
        _contractUri = contractUri;
    }

    function lockUri(uint id) public onlyRole(URI_MANAGER_ROLE) {
        require(id != 0, "cannot lock ID 0");
        emit uriLocked(_msgSender(), id, uri(id));
        lockedUris[id] = true;
    }

    function setUri(uint id, string memory newuri) public onlyRole(URI_MANAGER_ROLE) whenNotPaused {
        require(!lockedUris[id], "Uri for this id is permanently locked");
        _setURI(id, newuri);
    }

    function mintNewSBT(address account, uint256 id, uint256 amount, string memory uri)
        public onlyRole(MINTER_ROLE) whenNotPaused
    {
        _mintWithURI(account, id, amount, "", uri);
    }

    function mintExistingSBT(address account, uint256 id, uint256 amount) 
        public onlyRole(MINTER_ROLE) whenNotPaused
    {
        _mintWithoutURI(account, id, amount, "");
    }

    // implements SBT functionality by restricting transfer 
    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory /*ids*/,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal override virtual {
        require(from == address(0) || to == address(0), "You can't transfer this token");
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}