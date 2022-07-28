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

import "./Founding Settlers List.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
contract SettlersTickets is ERC1155, FoundingSettlersList, Ownable {

    /** @notice This contract always mints 100 tickets upon creation, even when there are not 100 qualified addresses.  
     *          If there are less than 100 qualified addresses, then some NFTs will not be distributed. The extras will
     *          be minted to the `extrasHolder` address.
     */
    address public extrasHolder = address(this);
    
    /// @notice This contract cannot mint more than 100 tickets.
    uint public constant initialSupply = 100;

    /// @notice This contract mints all 100 tickets when it is first created.
    uint public constant totalSupply = initialSupply;

    /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public name;
    string public symbol;

    // solhint-disable-next-line max-line-length
    /// @notice The metadata for these NFTs are stored immutably on Arweave at "https://lmdrlhtrixymo3ezatsyjyntx5ahrmbnyknxslmue6oq4ywfw2sq.arweave.net/WwcVnnFF8MdsmQTlhOGzv0B4sC3Cm3ktlCedDmLFtqU"
    /** @dev    This constructor mints and distributes 100 NFTs, one to each address on the Founding Settlers list.
     *          The `addresses` list is inherited from the "Founding Settlers List" contract, which disallows duplicate
     *          addresses. This ensures that each address on the list will receive only one ticket.
     */
    constructor() ERC1155(
    // solhint-disable-next-line max-line-length
        "https://lmdrlhtrixymo3ezatsyjyntx5ahrmbnyknxslmue6oq4ywfw2sq.arweave.net/WwcVnnFF8MdsmQTlhOGzv0B4sC3Cm3ktlCedDmLFtqU"
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

        /// @dev    Mints and sends a unique-ID ticket to each address in the Founding Settlers list.
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
    function addAddress(address toAdd) public onlyOwner {
        _addAddress(toAdd);
    }

    /** @dev    Removes an address from the Founding Settlers list. This will NOT result in the removed address losing 
     *          a Founding Settler's Ticket, however the Founding Settlers list may be referenced in other contracts, 
     *          and so the removed address will be excluded from receiving any future benefits. 
     *          Can only be called by the contract owner.
     */
    /// @param  toRemove The address which will be removed from the Founding Settlers List.
    function removeAddress(address toRemove) public onlyOwner {
        _removeAddress(toRemove);
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
}