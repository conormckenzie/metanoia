// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


import "./ERC2981/ERC2981(E)ContractWideRoyalties.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EmergencyPausable.sol";

// type conversions
import "./utils/libraries/TypeConversions.sol";

// uri encoding
import "./utils/libraries/Base64.sol";

interface IUriProvider {
    function uri(uint nftId) external view returns (string memory);
}

/// @title  Metaviva Pass NFT mint & storage
/// @author Conor McKenzie @ Metanoia Country
/** @notice This contract manages the "Metaviva Pass" collection as a set of standard, unique ERC-1155 NFTs.  
*         	You can use this contract to transfer your pass(es) to another address or do any other action supported by 
*         	the ERC-1155 standard.
*
*			Only the admins or users with the minter role can create new passes
*/
/** @dev    All non-view non-pure public functions in this contract other than those from OpenZeppelin's ERC-1155 
*          	contract (which this contract inherits from) are restricted to be accessible only by the owner.
*
*			Each NFT has a unique index number equal to its id, necessitating a unique uri for each NFT given that
*			Arweave naming does not match the ERC1155 standard's convention regarding uris.
*
*			OpenZeppelin's "Ownable" contract is used only for OpenSea support, as they currently don't automatically
*			grant the same privileges to those with the DEFAULT_ADMIN_ROLE role from AccessControl
*/

contract MetavivaPassNFTs is ERC1155Supply, Ownable, ERC2981ContractWideRoyalties_Evented, EmergencyPausable {

    event nameChanged(string oldName, string newName, address msgSender);
    event symbolChanged(string oldSymbol, string newSymbol, address msgSender);
    event imageChanged(string oldImage, string newImage, address msgSender);
    event externalLinkChanged(string oldUrl, string newUrl, address msgSender);
    event descriptionChanged(string oldDescription, string newDescription, address msgSender);
    event animationChanged(string oldAnimation, string newAnimation, address msgSender);
    event uriProviderChanged(address oldProvider, address newProvider, address msgSender);
    event contractUriChanged(string oldContractUri, string newContractUri, address msgSender);

	/// @notice The Minter role can mint new NFTs
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice The Uri Manager role can change the contractUri and individual components of an NFT's metadata
	bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    /// @notice The Royalty Manager role can change the ERC2981 royalty information
	bytes32 public constant ROYALTY_MANAGER_ROLE = keccak256("ROYALTY_MANAGER_ROLE");

	/// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0xD924ebF6e8328FA7F90DACf2C5cD0C4B7d2f0c32;

    /// @notice Specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 0;

    /// @dev    Some external applications use symbol to show info about the contract or NFT collection.
    string public symbol;

    /** URI VARIABLES
    *
    *   The following variables from "name" to "animation_url" are metadata components, used in the default uri
    *   for this contract. 
    *   
    *   If an alternate URI provider is used, these variables may be ignored.
    */

	/// @notice Some external applications use name to show info about the contract or NFT collection.
    string public name;

    /// @notice Stores a link to the image associated with each NFT (identical for all NFTs from this contract).
    // solhint-disable-next-line
    string public imageUri = "https://nuwwl3rgtj3xv3abedx2qeyhv5v5yqu5lskubvezaxzfhjcvkicq.arweave.net/bS1l7iaad3rsASDvqBMHr2vcQp1clUDUmQXyU6RVUgU";

    /// @notice Stores the description for each NFT (identical for all NFTs from this contract).
    // solhint-disable-next-line
    string public description = "Unlock exclusive experiences in the media & entertainment scene with this Classic MV Pass. This membership pass grants you access to closed-door movie premieres, meet & greet sessions, backstage passes, opportunities to participate in the process of making a film and many more.";

    /// @notice Stores the weblink that we be displayed on OpenSea and other marketplaces for buyers to learn more.
    string public external_url = "https://metaviva.io/mv-pass";

    /// @notice Stores a link to the animation associated with each NFT (identical for all NFTs from this contract).
    // solhint-disable-next-line
    string public animation_url = "https://hlvlv77qngzky4myd5roegi47vjneoxosizbffpne4v3654rfgxq.arweave.net/Ouq6__BpsqxxmB9i4hkc_VLSOu6SMhKV7Scrv3eRKa8";

    /** @notice Stores the address of the contract providing URI for this collection. By default it is this contract,
    *           however it can be set to use a different contract by an authorised user.
    */
    IUriProvider public uriProvider = IUriProvider(address(this));

    /// @notice This tracks the next available id greater than all existing ids which an NFT can be minted with.
    uint public nextAvailableId = 1;

	uint totalSupply_ = 0;
	/// @notice This returns the total supply of NFTs.
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

	/// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = "https://paf3w4ijyiplzi2vdxhmute54k7cg6ad5swmzibfpyzbaga7vfra.arweave.net/eAu7cQnCHryjVR3Oykyd4r4jeAPsrMygJX4yEBgfqWI";

    /// @dev    Constructs the contract using a blank uri. This contract's uri function hardcodes the metadata so there
    ///         is no need to provide a uri link here.  
	constructor() ERC1155("") {
		/// @dev Add the contract owner as the default admin
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		name = "Classic MV Pass";
        symbol = "Classic MV Pass";

		/// @dev    Sets the royalty rate for the ticket collection.
        _setRoyalties(royaltyRecipient, royaltyFee);
	}

	/** @notice Mints a new token with the specified ID to the specified address.
    *           This function cannot mint multiple NFTs with the same ID; this is to ensure uniqueness of each NFT.
    */
    /// @param  to The address which will receive the minted NFT
    /// @param  id The ID of the minted NFT
	function mintToken(address to, uint id) public whenNotPaused {
		require(
			hasRole(MINTER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only Minter and Admin can mint tokens"
		);
		require(totalSupply(id) == 0, "Cannot mint token that already exists");
        if (id >= nextAvailableId) {
            nextAvailableId = id + 1;
        } 
		_mint(to, id, 1, "");
	}

    /** @notice Mints a new token with the next available ID to the specified address.
    *           This function cannot mint multiple NFTs with the same ID; this is to ensure uniqueness of each NFT.
    */
    /** @dev    Due to the way nextAvailableId is tracked, this function should always succeed when called by an
    *           authorized user when the contract is not paused.
    */
    /// @param  to The address which will receive the minted NFT
    function mintNextAvailableToken(address to) public whenNotPaused {
        require(
			hasRole(MINTER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only Minter and Admin can mint tokens"
		);
		require(totalSupply(nextAvailableId) == 0, "Cannot mint token that already exists");
        nextAvailableId++;
		_mint(to, nextAvailableId-1, 1, "");
    }

	/** @notice Returns the contract URI for the collection. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     */
    /// @dev    This method is separate from ERC2981 and does not use the on-chain variables that RoyaltyInfo uses.
    /// @return contractUri A contract URI link containing metadata for the whole collection (not for indiviual NFTs)
    function contractURI() public view returns (string memory contractUri) {
        return _contractUri;
    }

	/** @notice Sets the contract URI for the collection. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     *          This method does NOT update the on-chain variables that ERC2981 uses. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called to change the OpenSea royalties, `setRoyaltyInfo(address, uint)` should also be called.
     */
    /// @param  newUri The new contract URI.
    function setContractUri(string calldata newUri) public whenNotPaused {
		require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the contract URI"
		);
        emit contractUriChanged(_contractUri, newUri, _msgSender()); 
        _contractUri = newUri;
    }

	/** @notice Sets the ERC2981 royalty info for the collection. 
     *          This method does NOT update the contractURI royalty values which are used by OpenSea. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called, `setContrctUri(string)` should also be called to point to a new metadata file which contains
     *          the updated royalty information.
     */
    /// @param  recipient The address which will receive royalty payments
    /// @param  feeInBasisPoints The royalty fee in basis points (units of 0.01%)
    function setRoyaltyInfo(address recipient, uint feeInBasisPoints) public whenNotPaused {
		require(
			hasRole(ROYALTY_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only Royalty Manager and Admin can set the royalty info"
		);
        royaltyRecipient = recipient;
        royaltyFee = feeInBasisPoints;
        _setRoyalties(royaltyRecipient, royaltyFee);
    }

    /// @notice Sets the name for the NFTs in this collection and for the collection as a whole.
    /// @param  newName The new name for the NFTs in this collection and for the collection as a whole.
    function setName(string memory newName) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the name"
		);
        emit nameChanged(name, newName, _msgSender());
        name = newName;
    }

    /// @notice Sets the symbol for the NFTs in this collection and for the collection as a whole.
    /// @param  newSymbol The new symbol for the NFTs in this collection and for the collection as a whole.
    function setSymbol(string memory newSymbol) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the symbol"
		);
        emit symbolChanged(symbol, newSymbol, _msgSender());
        symbol = newSymbol;
    }
    
    /// @notice Sets the image for the NFTs in this collection.
    /// @param  newImageUri The new image URI for the NFTs in this collection.
    function setImageUri(string memory newImageUri) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the image URI"
		);
        emit imageChanged(imageUri, newImageUri, _msgSender());
        imageUri = newImageUri;
    }

    /// @notice Sets the description for the NFTs in this collection.
    /// @param  newDescription The new description for the NFTs in this collection.
    function setDescription(string memory newDescription) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the description"
		);
        emit descriptionChanged(description, newDescription, _msgSender());
        description = newDescription;
    }

    /// @notice Sets the external URL for the NFTs in this collection.
    /// @param  newExternalUrl The new external URL for the NFTs in this collection.
    function setExternalUrl(string memory newExternalUrl) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the external URL"
		);
        emit externalLinkChanged(external_url, newExternalUrl, _msgSender());
        external_url = newExternalUrl;
    }
    
    /// @notice Sets the animation URL for the NFTs in this collection.
    /// @param  newAnimationUrl The new animation URL for the NFTs in this collection.
    function setAnimationUrl(string memory newAnimationUrl) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the animation URL"
		);
        emit animationChanged(animation_url, newAnimationUrl, _msgSender());
        animation_url = newAnimationUrl;
    }

    /// @notice Sets the URI provider for the NFTs in this collection.
    /// @param  newProvider The new URI provider for the NFTs in this collection.
    function setUriProvider(address newProvider) public whenNotPaused {
        require(
			hasRole(URI_MANAGER_ROLE, _msgSender()) ||
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only URI Manager and Admin can set the URI provider"
		);
        emit uriProviderChanged(address(uriProvider), newProvider, _msgSender());
        uriProvider = IUriProvider(newProvider);
    }

    /// @notice Returns the metadata for the NFT with the given ID.
    /** @dev    This uri call is fairly expensive, and should generally NOT be used within a contract transaction.
    *           This is included for compatibility with ERC1155, intended to be called from off-blockchain applications.
    *
    *           This uses on-chain metadata. On-chain metadata is required in order to easily display the  
    *           "Index Number" attribute with the same value as the NFT's ID, which is different for each NFT.
    *
    *           If the URI provider for this contract is set to a contract other than this one, then this function
    *           will return the result of the other contract's uri.
    */ 
    /// @param  nftId The ID of the NFT for which metadata will be returned
    /// @return metadata The metadata for the requested NFT, encode in base64 using the Base64 solidity library
	function uri(uint256 nftId) override(ERC1155) public view returns (string memory metadata) {
        if (address(uriProvider) != address(this)) {
            return uriProvider.uri(nftId);
        }
		// add each of the required attributes into the uri
        string memory _uriString = string(abi.encodePacked('{\n\t',
            '"name":"', name, '",\n\t',
            '"symbol":"', symbol, '",\n\t',
            '"image":"', imageUri, '",\n\t',
            '"description":"', description, '",\n\t',
            '"external_url":"', external_url, '",\n\t',
			'"animation_url": "', animation_url, '",\n\t',
			'"attributes": [',
				'\n\t\t{',
					'\n\t\t\t"trait_type":"',
					"Index Number",
					'",',
					'\n\t\t\t"value":"',
					TypeConversions.uintToString(nftId),
				'"\n\t\t}', ','
				'\n\t\t{',
					'\n\t\t\t"trait_type":"',
					"Classic",
					'",',
					'\n\t\t\t"value":"',
					'true',
				'"\n\t\t}',
			'\n\t]\n}'
        ));
        
		return string(abi.encodePacked(
            'data:application/json;base64,', 
            Base64.encode(bytes(_uriString))
        ));
	}  

    /// @dev augments OpenZeppelin's ERC1155Supply implementation to keep track of the global total supply. 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply_ += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                // uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = totalSupply_;
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    totalSupply_ = supply - amount;
                }
            }
        }
    }

	/// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base, AccessControl)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }
}