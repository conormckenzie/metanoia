// SPDX-License-Identifier: MIT

/*

███╗░░░███╗███████╗████████╗░█████╗░███╗░░██╗░█████╗░██╗░█████╗░
████╗░████║██╔════╝╚══██╔══╝██╔══██╗████╗░██║██╔══██╗██║██╔══██╗
██╔████╔██║█████╗░░░░░██║░░░███████║██╔██╗██║██║░░██║██║███████║
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║╚████║██║░░██║██║██╔══██║
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║██║░╚███║╚█████╔╝██║██║░░██║
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚═╝╚═╝░░╚═╝

    Metanoia is an ecosystem of products that aims to bring 
    real world utility into the web3 space. 

    Learn more about Metanoia in our whitepaper:            
    https://docs.metanoia.country/

    Join our community!
    https://discord.gg/YgUus2kddQ


    This is the contract responsible for Metanoia's soulbound
    "POAP" event tokens.

*/

pragma solidity 0.8.4;

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EmergencyPausable.sol";

contract SoulBoundTokensV1_1 is ERC1155MultiUri, AccessControl, Ownable, EmergencyPausable {

    event uriLocked(address indexed msgSender, uint indexed id, string indexed lockedUri);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    uint public nextUnusedToken;
    mapping (uint => bool) public lockedUris;
    string public _contractUri;

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public name;
    string public symbol;

    mapping(address => mapping(uint => uint)) _couponBalances;
    function couponBalances(address _address, uint id) public view returns(uint) {
        return _couponBalances[_address][id];
    }
    mapping (uint => string) public eventNames;
    uint public maximumIdCoupon;

    constructor() ERC1155("") {
        initialize();
    }

    function initialize() public virtual override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_MANAGER_ROLE, msg.sender);
        _grantRole(COUPON_MANAGER_ROLE, msg.sender);
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

    function registerCouponEvent(string memory eventName) public onlyRole(COUPON_MANAGER_ROLE) {
        maximumIdCoupon++;
        eventNames[maximumIdCoupon] = eventName;
    }

    function grantCoupons(address account, uint256 id, uint256 amount) 
        public onlyRole(COUPON_MANAGER_ROLE) 
    {
        require(id > 0 && id <= maximumIdCoupon, "coupon is not yet registered");
        _couponBalances[account][id] += amount;
    }

    function redeemCoupon(uint256 id) public {
        require (
            _couponBalances[msg.sender][id] >= 1,
            "ERRX"
            // cannot redeem coupon: user does not own coupon 
        );
        _couponBalances[msg.sender][id]--;
        _mint(msg.sender, id, 1, "");
    }

    // implements SBT functionality by restricting transfer 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {
        require(from == address(0) || to == address(0), "You can't transfer this token");
        super._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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