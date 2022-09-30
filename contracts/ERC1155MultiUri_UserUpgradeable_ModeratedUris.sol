// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155MultiUri_UserUpgradeable.sol";
import "./Moderated Uris.sol";
import "./EmergencyPausable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

/**
 * @dev Extension of ERC1155MultiURI that adds support for changing the metadata 
 *      associated with a token id, only for ids which correspond to unique NFTs,
 *      and only among an approved list of URIs.
 *      THIS IS NOT AN OPENZEPPELIN CONTRACT. It was created by Conor McKenzie.
 *
 * Useful for scenarios where multiple types of tokens are to be created with
 * metadata stored using a content-addressing naming scheme, such as when
 * stored on IPFS or Arweave, and where the option for holders to be able to 
 * change or upgrade their NFT(s)' metadata (within an approved set of 
 * changes) is desired. 
 * 
 * Caution: The following ERC1155 components have not been overwritten to  
 * maintain the integrity of OpenZeppelin's original ERC1155 contracts, but they 
 * should not be used:
 *      function _setURI(string memory)
 *    * function _mint(address, uint256, uint256, bytes memory)
 *
 * Note: _mint(address to, uint256 id, uint256 amount, bytes memory data) 
 * from OpenZeppelin's ERC1155 contract is replaced with: 
 * _mintWithoutURI(address to, uint256 id, uint256 amount, bytes memory data),
 * _mintWithURI(address to, uint256 id, uint256 amount, bytes memory data, 
 *      string memory newuri)
 * for minting existing tokens and new tokens, respectively. 
 * These functions both call _mint(address, uint256, uint256, bytes memory)
 * to mint tokens.
 */

// interface IModeratedUris {
//     function isMetadataApprovedForId(uint id, string memory metadata_uri) external view returns(bool);
//     function isMetadataApprovedForAll(string memory metadata_uri) external view returns(bool);
//     function approveMetadataForId(uint id, string memory metadata_uri) external;
//     function approveMetadataForAll(string memory metadata_uri) external;
//     function unapproveMetadataForId(uint id, string memory metadata_uri) external;
//     function unapproveMetadataForAll(string memory metadata_uri) external;
// }

abstract contract ERC1155MultiUri_UserUpgradeable_ModeratedUris is 
ERC1155MultiUri_UserUpgradeable, ModeratedUris {

    // IModeratedUris public moderatedUris;
    
    // function setModeratedUrisAddress(address address_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     moderatedUris = IModeratedUris(address_);
    // }

    /*  
     * @dev Adds a require statement to check the user-given URI against a list
     *      of pre-approved metadata, and then runs _safeUpdateURI(...)
     */
    function safeUpdateURI(
        string memory newuri,
        address owner,
        uint256 id
    ) public virtual {
        require(
            isMetadataApprovedForId(id, newuri), 
            string(abi.encode(
                "Given metadata is not approved for token id ", id
            ))
        );
        _safeUpdateURI(newuri, owner, id);
    }

    /*  
     * @dev Overrides _mintWithURI(...) from ERC1155MultiURI, providing an 
     *      updated require message and an additional condition to check if a
     *      token is non-mintable.
     */
    function _mintWithURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newuri
    ) internal virtual override mintsTokens(id) {
        require (
            !exists(id), 
            "Cannot change metadata of existing token via minting"
        );
        require(
            isMetadataApprovedForId(id, newuri), 
            string(abi.encode(
                "Given metadata is not approved for token id ", id)
            )
        );

        _setURI(id, newuri);
        _mint(to, id, amount, data);
    }

    function initialize() public virtual override {
        // console.log("ERC1155MultiUri_UserUpgradeable_ModeratedUris: initializer");
        super.initialize();
    }

    /*  
     * @dev Override required by Solidity compiler
     */
     // not sure if this is correct or not
    function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}


