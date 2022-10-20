// WARNING: IN DEVELOPMENT

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./legacy/Address List.sol";
import "./Uint256 List.sol";

abstract contract ERC1155OwnerTracking is ERC1155Supply {
    
    // use a multi-key database
    // function getKey(address _address, uint _id) public pure returns(uint key) {
    //     return uint(keccak256(abi.encode(this.getKey.selector, _address, _id)));
    // }
    // mapping(uint => uint) fht;
    // uint tempest =  uint(keccak256(abi.encode()));

    // // maps address to ID list with length, searchable by ID, representing the IDs that this address owns
        // this is what we need, but the subtleties of Solidity make it too uncertain to develop this feature
    // mapping(address => Uint256List) idsOwnedByAddess;

    // // maps ID to list of addresses with length, searchable by address, representing the addresses that own this ID
        // this is what we need, but the subtleties of Solidity make it too uncertain to develop this feature
    // mapping(uint => AddressList) addressesThatOwnId;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        // ownedBy : no longer owned by from
        // ownedBy : now owned by to
        // ownersOf : no longer owned by from
        _safeTransferFrom(from, to, id, amount, data);
    }
}