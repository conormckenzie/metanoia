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


    This is the contract that mints the collection of 
    'Founding Settler's ticket' NFTs
*/

pragma solidity 0.8.4;

import "./legacy/Address List.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

/// @title  Founding Settlers Tickets NFT mint & storage
/// @author Conor McKenzie
/** @notice This contract mints the "Founding Settler's tickets" collection as a set of 100 standard ERC-1155 NFTs.  
 *          You can use this contract to transfer your ticket(s) to another address or do any other action supported by 
 *          the ERC-1155 standard.
 */
/** @dev    All non-view non-pure public functions in this contract other than those from OpenZeppelin's ERC-1155 
 *          contract (which this contract inherits from) are restricted to be accessible only by the owner.
 *
 *          The Founding Settlers List may exceed 100 addresses after minting, by use of the `addAddress` function. 
 */
contract SettlersTickets is ERC1155Supply, _AddressList, Ownable, ERC2981ContractWideRoyalties {

    /** @notice This contract always mints 100 tickets upon creation, even when there are not 100 qualified addresses.  
     *          If there are less than 100 qualified addresses, then some NFTs will not be distributed. The extras will
     *          be minted to the `extrasHolder` address.
     */
    /** @dev    This value is used as a constant; however the `constant` keyword cannot be used because  
     *          `address(this)` is not compile-time constant.
     */
    address public extrasHolder = address(this);

    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;
    
    /// @notice This contract cannot mint more than 100 tickets.
    uint public constant initialSupply = 100;

    /// @notice This contract mints all 100 tickets when it is first created.
    function totalSupply() public pure returns(uint256) {
        uint totalSupply_ = initialSupply;
        return totalSupply_;
    } 

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public name;
    string public symbol;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = "https://g4kxt42j3axbuh4zuif4fdlcinjueo2q7ns2arareajwmpuneb3q.arweave.net/NxV580nYLhofmaILwo1iQ1NCO1D7ZaBEESATZj6NIHc";

    // solhint-disable-next-line max-line-length
    /// @notice The metadata for these NFTs are stored immutably on Arweave at "https://lmdrlhtrixymo3ezatsyjyntx5ahrmbnyknxslmue6oq4ywfw2sq.arweave.net/WwcVnnFF8MdsmQTlhOGzv0B4sC3Cm3ktlCedDmLFtqU"
    /** @dev    This constructor mints and distributes 100 NFTs, one to each address on the Founding Settlers list.
     *          The `addresses` list is inherited from the "Founding Settlers List" contract, which disallows duplicate
     *          addresses. This ensures that each address on the list will receive only one ticket.
     */
    constructor() ERC1155(
    // solhint-disable-next-line max-line-length
        "https://n4iddozenxh3wts7q3tjzudhzfvlzqtqezfrshpyiye7wuwqugba.arweave.net/bxAxuyRtz7tOX4bmnNBnyWq8wnAmSxkd-EYJ-1LQoYI"
    ) {
        
        require (addresses.length <= initialSupply, "address list is too large: # of addresses > initial supply");

        name = "Metanoia Founding Settlers Ticket";
        symbol = "METANOIA TICKET";
        
        /** @dev    The `_initList` function is inherited from the `FoundingSettlersList` contract.
         *          `_initList` initializes the list of Founding Settlers and populates it with a pre-approved set of 
         *          qualified addresses. 
         */
        _initList();

        /** @dev    Temporary variable which acts as a counter that loops through the addresses in the Founding 
         *          Settlers List and as the ID to assign to the next-minted NFT.     
         */        
        uint _tokenID;

        /// @dev    Sets the royalty rate for the ticket collection.
        _setRoyalties(royaltyRecipient, royaltyFee);

        /** @dev    Mints and sends a unique-ID ticket to each address in the Founding Settlers list.
         *          This contract will fail (loudly) to deploy if it cannot mint to any of the addresses in the 
         *          Founding Settlers list.
         */
        for (_tokenID = 1; _tokenID <= addresses.length; _tokenID++) {
            _mint(addresses.list[_tokenID], _tokenID, 1, "");
        }

        /** @dev    In the event that less than 100 addresses are in the Founding Settlers list, mint and send the 
         *          remaining tickets to the `extrasHolder` address.
         */
        for (; _tokenID <= initialSupply; _tokenID++) {
            _mint(extrasHolder, _tokenID, 1, "");
        }
    }

    /** @dev    Adds an address to the Founding Settlers list. This will NOT result in the added address receiving a
     *          Founding Settler's Ticket, however the Founding Settlers list may be referenced in other contracts, and 
     *          so the added address may receive future benefits such as token airdrops.
     *          Can only be called by the contract owner.
     */
    /// @param  toAdd The address which will be added to the Founding Settlers List.
    /// @param  revertOnFail Whether to revert or continue (returning false) when failing to add the address.
    function addAddress(address toAdd, bool revertOnFail) public onlyOwner returns(bool, string memory errMsg) {
        if (revertOnFail) {
            _addAddress(toAdd);
            return (true, "");
        }
        else {
            return _tryToAddAddress(toAdd);
        }
    }

    /** @dev    Removes an address from the Founding Settlers list. This will NOT result in the removed address losing 
     *          a Founding Settler's Ticket, however the Founding Settlers list may be referenced in other contracts, 
     *          and so the removed address will be excluded from receiving any future benefits. 
     *          Can only be called by the contract owner.
     */
    /// @param  toRemove The address which will be removed from the Founding Settlers List.
    /// @param  revertOnFail Whether to revert or continue (returning false) when failing to remove the address.
    function removeAddress(address toRemove, bool revertOnFail) public onlyOwner returns(bool, string memory errMsg) {
        if (revertOnFail) {
            _removeAddress(toRemove);
            return (true, "");
        }
        else {
            return _tryToRemoveAddress(toRemove);
        }
    }

    /** @dev    Sends a Founding Settler's Ticket NFT from the `extrasHolder` address to a given address.
     *          The NFT with the specified ID must be owned by the `extrasHolder` address. 
     *          Can only be called by the contract owner.
     */
    /// @param  to The address which the NFT will be sent to.
    /// @param  ticketID The ID of the NFT which will be sent.
    function sendTicket(address to, uint ticketID) public onlyOwner {
        _safeTransferFrom(extrasHolder, to, ticketID, 1, "");
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
    function setContractUri(string calldata newUri) public onlyOwner {
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
    function setRoyaltyInfo(address recipient, uint feeInBasisPoints) public onlyOwner {
        royaltyRecipient = recipient;
        royaltyFee = feeInBasisPoints;
        _setRoyalties(royaltyRecipient, royaltyFee);
    }

    /** @dev    Provides users and external contracts low-level view access to the Metanoia Founding Settlers List.
     *          This list does not represent, nor should it be used as, a list of owners of the Founding Settlers NFTs.
     *
     *          This function allows view access to `addresses.length`.
     */
    /// @return length | the number of addresses in the Founding Settlers List.
    function getMFS_length() external view returns(uint length) {
        return addresses.length;
    }

    /** @dev    Provides users and external contracts low-level view access to the Metanoia Founding Settlers List.
     *          This list does not represent, nor should it be used as, a list of owners of the Founding Settlers NFTs. 
     *
     *          This function allows view access to `addresses.list`.
     */
    /// @return FoundingSettlerAddress | the address that is bound to the given ID.
    function getMFS_list(uint ID) external view returns(address FoundingSettlerAddress) {
        return addresses.list[ID];
    }

    /** @dev    Provides users and external contracts low-level view access to the Metanoia Founding Settlers List.
     *          This list does not represent, nor should it be used as, a list of owners of the Founding Settlers NFTs. 
     *
     *          This function allows view access to `addresses.listInv`.
     */
    /// @return addressID | the ID that is bound to the given address.
    function getMFS_listInv(address FoundingSettlerAddress) external view returns(uint addressID) {
        return addresses.listInv[FoundingSettlerAddress];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155,ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
