// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155MultiUri.sol";

contract TestERC1155MultiUri is ERC1155MultiUri {

    constructor() ERC1155("") {}

    function setURI(uint id, string memory newuri) external {
        _setURI(id, newuri);
    }

    function mintWithURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newuri
    ) external {
        _mintWithURI(to, id, amount, data, newuri);
    }

    function mintWithoutURI(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _mintWithoutURI(to, id, amount, data);
    }
}