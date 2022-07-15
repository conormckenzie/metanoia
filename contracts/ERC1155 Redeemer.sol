//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITypedNftSender {
    function getNftType(uint nftId) external view returns (uint);
}

contract ERC1155Redeemer is ERC1155Holder, Ownable {

    mapping (address => mapping (uint => uint)) public selfBalances;
    mapping (address => bool) whitelist; //not implemented yet 

    /* 
    contractAddress refers to this contract,
     */
    event ERC1155Received (
        uint indexed date,
        address indexed from,
        uint indexed nftId,
        address contractAddress, 
        address nftContractAddress,
        uint nftType
    );

    /*  WARNING: The current implementation of this allows anyone to call the function 
        regardless of whether they have actually sent the ERC1155 to this contract.
        This MUST be fixed before production.

        This has been fixed by tracking this contract's address internally and 
        checking it against this contract's balance from the sending contract.
        This needs to be tested before this message can be removed.
    */
    function onERC1155Received(
        address /*operator*/,
        address from,
        uint256 nftId,
        uint256 value,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(value == 1, "Please redeem only one NFT at a time");
        require(
            IERC1155(msg.sender).balanceOf(address(this), nftId) 
            == selfBalances[msg.sender][nftId] + 1,
            "Redeemer contract's balance of this nft is not the expected value"
        );
        try ITypedNftSender(msg.sender).getNftType(nftId) returns (uint) {
            require(
                ITypedNftSender(msg.sender).getNftType(nftId) >= 0, 
                "Nft Minter contract provides invalid nftType"
            );
            require(
                ITypedNftSender(msg.sender).getNftType(nftId) != 3, 
                "Cannot redeem NFT type 3 (infinite-use) via this contract."
            );
        } catch {
            revert("Nft Minter contract does not provide getNftType external function");
        }
        uint nftType = ITypedNftSender(msg.sender).getNftType(nftId);
        selfBalances[msg.sender][nftId] += 1;
        emit ERC1155Received(block.timestamp, from, nftId, address(this), msg.sender, nftType);
        return this.onERC1155Received.selector;
    }

    // needs testing to make sure it fails successfully
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] memory /*nftIds*/,
        uint256[] memory /*values*/,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert("Please redeem only one NFT at a time to this redeemer contract");
    }

    // TO DO: upgrade the error messages to show the relevant values
    // TO DO: test this function
    function returnERC1155(address to, address nftContract, uint nftId) public onlyOwner {
        require(
            IERC1155(nftContract).balanceOf(address(this), nftId) 
            == selfBalances[nftContract][nftId],
            "Redeemer contract's balance of this nft with this id is not the expected value"
        );
        require(selfBalances[nftContract][nftId] >= 1,
            "Redeemer contract's balance of this nft with this id is zero"
        );
        IERC1155(nftContract).safeTransferFrom(address(this), to, nftId, 1, "");
        selfBalances[nftContract][nftId] -= 1;
    }

    // needs testing
    function checkThisContractsBalance(address nftContract, uint nftId) 
    public view returns (uint) {
        return IERC1155(nftContract).balanceOf(address(this), nftId);
    }
}