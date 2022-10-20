// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SoulBoundToken is ERC1155MultiUri, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mintNewSBT(address account, uint256 id, uint256 amount, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintWithURI(account, id, amount, "", uri);
    }

    function mintExistingSBT(address account, uint256 id, uint256 amount) 
        public 
        onlyRole(MINTER_ROLE)
    {
        _mintWithoutURI(account, id, amount, "");
    }

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