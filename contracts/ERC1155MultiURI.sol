// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// ERC1155MultiURI contract (created by Conor McKenzie)

/**
 * @dev Extension of ERC1155Supply that adds support for arbitrary metadata 
 *      URIs per token id.
 *      THIS IS NOT AN OPENZEPPELIN CONTRACT. It was created by Conor McKenzie.
 *      The OpenZeppelin contract which accomplishes a similar purpose is
 *      OpenZeppelin's ERC1155URIStorage contract.
 *
 * Useful for scenarios where multiple types of tokens are to be created with
 * metadata stored using a content-addressing naming scheme, such as when
 * stored on IPFS or Arweave. 
 * 
 * Note: ERC1155Supply is needed to check if a token already exists, to prevent
 * modification of metadata for an existing token and enforce the provision of
 * metadata for new tokens. 
 * 
 * Caution: The following ERC1155 components have not been overwritten to  
 * maintain the integrity of OpenZeppelin's original ERC1155 contracts, but they 
 * should not be used:
 *    * string private _uri
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
abstract contract ERC1155MultiURI is ERC1155Supply {

    /**
     * @dev Replaces <_uri> as the variable which holds metadata information.
     *
     * Syntax:      _uris[id]
     * Description: stores the URI for the given token ID
     */
    mapping (uint256 => string) private _uris;

    function uri(uint256 id) 
    public view virtual override returns (string memory) {
        return _uris[id];
    }

    function _setURI(uint id, string memory newuri) internal virtual {
        _uris[id] = newuri;
    }

    function _mintWithURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newuri
    ) internal virtual {
        require (!exists(id), "Cannot change metadata of existing token");

        _setURI(id, newuri);
        _mint(to, id, amount, data);
    }

    function _mintWithoutURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require (exists(id), "Please provide metadata for new token");

        _mint(to, id, amount, data);
    }
}