/*
 *Submitted for verification at polygonscan.com on 2022-xx-xx (YYYY-MM-DD)
*/

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


    This is the contract responsible for the minting and
    storage of the Founding Citizen NFTs.

*/

// TO-DO: update this contract to move metadata on-chain

import "./ERC1155MultiUri_UserUpgradeable_ModeratedUris.sol";

pragma solidity 0.8.1;

contract FoundingCitizensNftMintStorage is 
ERC1155MultiUri_UserUpgradeable_ModeratedUris {
    address public extrasHolder = address(this);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_LOADER_ROLE = keccak256("URI_LOADER_ROLE");
    
    uint public constant initialSupply = 10; //for testing - REMVOVE THIS LINE in production code
    // uint public constant initialSupply = 10000;
    uint public constant maxSupply = initialSupply;

    uint public totalSupply;
    uint public nextUnusedToken = 1;

    string public name;
    string public symbol;

    /*  
    *  @dev Handles checks and effects for minting a new token. Use for functions that mint new tokens.
    */
    modifier isNewMint(uint _tokenID, uint _newSupply) {
        require(!exists(_tokenID), "FoundingNFTMintStorage: ERR 1"); 
            // string(abi.encode(
            //     "You have tried to call a mint function on an existing token while providing a new metadata URI.", 
            //     "Please call the correponding function without URI as a parameter." 
            // ))
        if (_tokenID >= nextUnusedToken) {
            nextUnusedToken = _tokenID + 1;
        }
        totalSupply += _newSupply;
        _;
    }

    constructor() ERC1155("URI not applicable: Using ERC1155MultiURI") {

        name = "Metanoia Founding Citizens NFT";
        symbol = "MFS NFT";

    }

    function getNextUnusedToken() external view returns(uint) {
        return nextUnusedToken;
    }

    function getMaxSupply() external pure returns(uint) {
        return maxSupply;
    }

    /*  
    *  @dev Pre-loads the URI for each token's metadata.
    *       Note: This can only be called on NFTs that have not been minted yet
    */
    function preLoadURIs(uint[] memory ids, string[] memory uris) external {
        require(
            hasRole(URI_LOADER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        for (uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];
            string memory uri = uris[i];
            require(!exists(id), "Cannot change URI for existing token");
            _setURI(id, uri);
        }
    }

    /*  
    *  @dev Mints the next unminted NFT in the collection.
    */
    function mintNextNftToAddress(address to) external isNewMint(nextUnusedToken, 1) {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        require(
            nextUnusedToken <= maxSupply, 
            string(abi.encodePacked(
                "Cannot mint more than <maxSupply> (", maxSupply, ") tokens"
            ))
        );
        _mintWithURI(to, nextUnusedToken, 1, "", uri(nextUnusedToken));
        nextUnusedToken++;
    }

}