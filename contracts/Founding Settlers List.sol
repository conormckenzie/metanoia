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


    This is a supporting contract for the Founding Settlers NFT 
    mint, airdrop and raffle. It manages the list of founding
    settlers.
*/

pragma solidity 0.8.4;

/// @title  Founding Settlers List
/// @author Conor McKenzie
/** @dev    This contract is to be deployed ONLY as part of the Metanoia Founding Settler's NFT mint. 
 *          It can be referenced in other smart contracts which need it through the interface of the Metanoia Founding 
 *          Settler's NFT mint smart contract.
 */
contract FoundingSettlersList {

    /** @dev    AddressList maintains a list of addresses, each address belonging to one of the founding settlers. 
     *          These are stored in a linked-list hashmap hybrid that performs O(1) lookups, insertions and deletions.
     *          Invariants:
     *          (1) Each ID is a uint256
     *          (2) Each address in the list is associated with a unique ID 
     *          (3) Each ID other than ID 0 is associated with a unique address
     *          (4) An address that is not in the list maps to ID 0
     *          (5) All IDs from 1 to the length of the list map to an address that is not the zero address
     *          (6) All IDs greater than the length of the list and ID 0 map to the zero address 
     */
    struct AddressList {

        /** @dev    `length` equals the number of addresses currently in the list. 
         *          Each address in the list has an ID from 1 to `addresses.length`. 
         */
        uint length;

        /** @dev    `list` maps an address ID to the address itself.
         *          `list` is 1-indexed, not 0-indexed. This is to allow unlisted addresses to map to ID 0.
         */
        mapping(uint => address) list;

        /// @dev    `listInv` maps an address to that address's ID.
        mapping(address => uint) listInv; 
    }

    /// @dev `addresses` is the list of addresses. 
    AddressList public addresses;

    /// @dev    Adds an address to list, binding it to the lowest available ID.
    /// @param  _address The address to add to the list
    function _addAddress(address _address) internal {
        
        /// @dev    `addresses.list` is 1-indexed not 0-indexed
        addresses.list[addresses.length+1] = _address; 
        addresses.listInv[_address] = addresses.length+1;
        addresses.length++;
    }

    /** @dev    Conceptually, this function removes an address from the list, unbinds the last address in the list from 
     *          its ID, and rebinds that address to the ID previously bound to the removed address. 
     *          The actual implementation is organized by performing all required operations on `list`, then performing
     *          all required operations on `listInv`.
     */
    /// @param  _address The address to remove from the list
    function _removeAddress(address _address) internal {
        
        uint removedID = addresses.listInv[_address];
        address removedAddress = _address;

        uint lastID = addresses.length;
        address lastAddress = addresses.list[addresses.length];

        /** @dev    Modifies `list` so the ID of the removed address maps to the last address, and the ID of the last 
         *          address maps to the zero address. 
         */
        addresses.list[removedID] = addresses.list[lastID];
        delete addresses.list[lastID];

        /** @dev    Modifies `listInv` so the ID of the removed address no longer maps to the removed address but 
         *          instead to the address that was previously last in the list. Then modifies `listInv` so that the
         *          the ID of the former last address maps to the zero address. 
         */
        addresses.listInv[removedAddress] = addresses.listInv[lastAddress];
        delete addresses.listInv[lastAddress];
        
        /// @dev    Finally, decrements the length of the list.
        addresses.length--;
    }

    /// @dev    Initializes the address list with a set pre-approved list of addresses. 
    function _initList() internal {
        addresses.length = 0;
        _addAddress(0xc0ffee254729296a45a3885639AC7E10F9d54979);
        _addAddress(0x59eeD72447F2B0418b0fe44C0FCdf15AAFfa1f77);
        _addAddress(0xCb172d8fA7b46b53A6b0BDACbC5521b315D1d3F7);
        _addAddress(0x5061b6b8B572776Cff3fC2AdA4871523A8aCA1E4);
        _addAddress(0xff2710dF4D906414C01726f049bEb5063929DaA8);
        _addAddress(0xb3c8801aF1E17a4D596E7678C1548094C872AE0D);
    }
}