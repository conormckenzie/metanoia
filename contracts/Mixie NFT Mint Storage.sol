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
import "./EmergencyPausable.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

pragma solidity 0.8.4;

interface IUriProvider {
    function setURI(uint id, string memory newuri) external;
    function setURIs(uint[] memory ids, string[] memory uris) external;
    function uri(uint id) external view returns(string memory);
}

contract MixieNftMintStorage is 
ERC1155MultiUri_UserUpgradeable_ModeratedUris, EmergencyPausable, ERC2981ContractWideRoyalties {
    address public extrasHolder = address(this);

    mapping (uint256 => string) private _alternateUris;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_LOADER_ROLE = keccak256("URI_LOADER_ROLE");
    
    uint public constant initialSupply = 10; //for testing - REMVOVE THIS LINE in production code
    // uint public constant initialSupply = 10000;
    uint public constant maxSupply = initialSupply;

    uint public totalSupply;
    uint public nextUnusedToken = 1;

    string public name;
    
    string public symbol;

    // provider 0 is this contract's parent's `_uris` and the deafult inherited `uris(uint id)` function; 
    // other providers from other contracts may be added in the future; provider 1 will probably be on-chain uri
    // each id can use any of the uri providers, independent of any other id
    mapping (uint256 => uint) private _uriProviderIndexForThisId; 

    // indexes the uri provider addresses
    mapping (uint => address) public uriProviders;

    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = "";

    /*  
    *  @dev Handles checks and effects for minting a new token. Use for functions that mint new tokens.
    */
    modifier isNewMint(uint _tokenID, uint _newSupply, address _to) {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Minter or Admin"
        );
        require(
            nextUnusedToken <= maxSupply, 
            string(abi.encodePacked(
                "Cannot mint more than <maxSupply> (", maxSupply, ") tokens"
            ))
        );
        require(!exists(_tokenID), "FoundingNFTMintStorage: ERR 1"); 
            // string(abi.encode(
            //     "You have tried to call a new mint function on an existing token.", 
            //     "This is probably a software bug." 
            // ))
        
        if (_tokenID >= nextUnusedToken) {
            nextUnusedToken = _tokenID + 1;
        }
        totalSupply += _newSupply;
        _;
    }

    // constructor cannot easily be removed due to being defined in the OpenZeppelin ERC1155 base contract
    constructor() ERC1155("URI not applicable: Using ERC1155MultiURI") {
        name = "Metanoia Founding Citizens NFT";
        symbol = "MFS NFT";
        _setRoyalties(royaltyRecipient, royaltyFee);
    }

    function getNextUnusedToken() external view returns(uint) {
        return nextUnusedToken;
    }

    function getMaxSupply() external pure returns(uint) {
        return maxSupply;
    }

    /** @notice Returns the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     */
    /// @dev    This method is separate from ERC2981 and does not use the on-chain variables that RoyaltyInfo uses.
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /** @dev    Sets the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     *          This method does NOT update the on-chain variables that ERC2981 uses. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called to change the OpenSea royalties, `setRoyaltyInfo(address, uint)` should also be called.
     */
    /// @param  newUri The new contract URI.
    function setContractUri(string calldata newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractUri = newUri;
    }

    /** @dev    Sets the ERC2981 royalty info for the collection of tickets. 
     *          This method does NOT update the contractURI royalty values which are used by OpenSea. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called, `setContrctUri(string)` should also be called to point to a new metadata file which contains
     *          the updated royalty information.
     */
    /// @param  recipient The address which will receive royalty payments
    /// @param  feeInBasisPoints The royalty fee in basis points (units of 0.01%)
    function setRoyaltyInfo(address recipient, uint feeInBasisPoints) public onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyRecipient = recipient;
        royaltyFee = feeInBasisPoints;
        _setRoyalties(royaltyRecipient, royaltyFee);
    }

    // check that this works if provider for `id` is 0
    function uri(uint256 id) 
    public view virtual override returns (string memory) {
        if (_uriProviderIndexForThisId[id] == 0) {
            return super.uri(id);
        }
        else {
            return IUriProvider(uriProviders[_uriProviderIndexForThisId[id]]).uri(id);
        }
    }

    function _setAlternateURI(uint id, string memory newuri) internal {
        _alternateUris[id] = newuri;
    }

    /*  
    *  @dev Pre-loads the URI for each token's metadata.
    *       Note: This can only be called on NFTs that have not been minted yet
    */
    function preLoadURIs(uint[] memory ids, string[] memory uris) external whenNotPaused {
        require(
            hasRole(URI_LOADER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        for (uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];
            string memory newuri = uris[i];
            require(!exists(id), "Cannot change URI for existing token");
            _setAlternateURI(id, newuri);
        }
    }

    function preLoadFutureURIs(uint[] memory ids, string[] memory uris) external whenNotPaused {
        require(
            hasRole(URI_LOADER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        for (uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];
            string memory newuri = uris[i];
            _setURI(id, newuri);
        }
    }

    // need to restrict this to only verify once the upgrade has been approved
    // need an "approved" marker variable
    function upgradeUri (uint id, uint provider) public whenNotPaused {
        if (provider == 0 || _uriProviderIndexForThisId[id] == 0) {
            _setURI(id, _alternateUris[id]);
        }
        else {
            _uriProviderIndexForThisId[id] = provider;
        }
    }

    /*  
    *  @dev Mints the next unminted NFT in the collection.
    */
    function mintNextNftToAddress(address to) external isNewMint(nextUnusedToken, 1, to) whenNotPaused {
        
        // all logic regarding nextUsedToken etc. is handled by modifier
        // nextUnusedToken is incremeneted by modifier
        _mintWithURI(to, nextUnusedToken-1, 1, "", uri(nextUnusedToken-1));
    }

    function supportsInterface(bytes4 interfaceId) 
    public view virtual override(
        ERC1155MultiUri_UserUpgradeable_ModeratedUris, 
        AccessControl, 
        ERC2981Base
    ) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId || 
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}