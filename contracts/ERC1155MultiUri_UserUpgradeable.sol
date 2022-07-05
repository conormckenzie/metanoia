// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155MultiUri.sol";

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
abstract contract ERC1155MultiUri_UserUpgradeable is ERC1155MultiUri {
    
    modifier mintsTokens(uint id) {
        require (!cannotMintMore[id], "Token is non-mintable");
        _;
    }
    
    /*  
     * @dev Tracks whether a given token's supply cannot be increased,
     *      i.e. the token is non-mintable.
     */
    mapping(uint => bool) public cannotMintMore;

    /*  
     * @dev Checks whether a token is a unique and non-mintable. 
     */
    function isPermanentlyUnique(uint id) public view returns(bool) {
        return (totalSupply(id) == 1 && cannotMintMore[id]);
    }

    /*  
     * @dev Sets a token to be non-mintable.
     *
     * CAUTION: This cannot be undone!
     */
    function _lockMinting(uint id) internal {
        cannotMintMore[id] = true;
    }

    /*  
     * @dev Uses the same code pattern as OpenZeppelin's safeTransferFrom 
     *      function.
     */
    function _safeUpdateURI(
        string memory newuri,
        address owner,
        uint256 id
    ) internal virtual {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            "ERC1155MultiURI_UserUpgradeable: caller is not owner nor approved"
        );
        require(
            isPermanentlyUnique(id), 
            "Can only change URI on a token that is permanently unique"
        );
        uint256 fromBalance = balanceOf(owner, id);
        require(
            fromBalance == 1, 
            string(abi.encode(
                "ERC1155MultiURI_UserUpgradeable: given owner ", 
                owner,
                " does not own this NFT"
            ))
        );
        _setURI(id, newuri);
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

        _setURI(id, newuri);
        _mint(to, id, amount, data);
    }

    /*  
     * @dev Overrides _mintWithoutURI(...) from ERC1155MultiURI, providing an 
     *      additional condition to check if a token is non-mintable.
     */
    function _mintWithoutURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override mintsTokens(id) {
        require (exists(id), "Please provide metadata for new token");

        _mint(to, id, amount, data);
    }
}