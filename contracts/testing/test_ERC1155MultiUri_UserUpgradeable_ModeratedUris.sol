// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155MultiUri_UserUpgradeable_ModeratedUris.sol";
import "hardhat/console.sol";


// ERC1155MultiURI_UserUpgradeable contract (created by Conor McKenzie)

/**
 * @dev Extension of ERC1155MultiURI that adds support for changing the metadata 
 *      associated with a token id, only for ids which correspond to unique NFTs.
 *      THIS IS NOT AN OPENZEPPELIN CONTRACT. It was created by Conor McKenzie.
 *
 * Useful for scenarios where multiple types of tokens are to be created with
 * metadata stored using a content-addressing naming scheme, such as when
 * stored on IPFS or Arweave, and where the option for holders to be able to 
 * change or upgrade their NFT(s) is desired. 
 *
 * Caution: this contract does not perform any checks for what metadata URI is
 * provided. If moderation of the content of NFT metadata is required, it must  
 * be implemented separately, for example by use of an approved-URI list. 
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
contract test_ERC1155MultiUri_UserUpgradeable_ModeratedUris is ERC1155MultiUri_UserUpgradeable_ModeratedUris{
    
    constructor() ERC1155("") {
        initialize();
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        console.log("test_ERC1155MultiUri_UserUpgradeable_ModeratedUris: hasRole");
        return super.hasRole(role, account);
    }
    
    function initialize() public virtual override {
        // console.log("test_ERC1155MultiUri_UserUpgradeable_ModeratedUris: initializer");
        super.initialize();
    }
    /*  
     * @dev Checks whether a token is a unique and non-mintable. 
     */
    function test_isPermanentlyUnique(uint id) public view returns(bool) {
        return isPermanentlyUnique(id);
    }

    /*  
     * @dev Sets a token to be non-mintable.
     *
     * CAUTION: This cannot be undone!
     */
    function lockMinting(uint id) external {
        _lockMinting(id);
    }

    function setURI(uint id, string memory newuri) external {
        _setURI(id, newuri);
    }

    /*  
     * @dev Overrides _mintWithURI(...) from ERC1155MultiURI, providing an 
     *      updated require message and an additional condition to check if a
     *      token is non-mintable.
     */
    function mintWithURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newuri
    ) external {
        _mintWithURI(to, id, amount, data, newuri);
    }

    /*  
     * @dev Overrides _mintWithoutURI(...) from ERC1155MultiURI, providing an 
     *      additional condition to check if a token is non-mintable.
     */
    function mintWithoutURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _mintWithoutURI(to, id, amount, data);
    }
}