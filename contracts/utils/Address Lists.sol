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

// import "hardhat/console.sol";

/// @title  Address List
/// @author Conor McKenzie
/** @dev    This contract is to be deployed ONLY as part of the Metanoia Founding Settler's NFT mint. 
 *          It can be referenced in other smart contracts which need it through the interface of the Metanoia Founding 
 *          Settler's NFT mint smart contract.
 */
contract AddressLists {

    // ERROR CODES:
    // ERR-A1 : "Cannot add address that is already in the list"
    // ERR-A2 : "Cannot add the zero address to the list"
    // ERR-A3 : "Cannot remove address that is already not in the list"
    // ERR-A4 : "Cannot remove the zero address from the list"
    // ERR-A5 : "Cannot initialize a list that is not empty"
    string constant private errMsg1_addExisting = "ERR-A1";
    string constant private errMsg2_addZero = "ERR-A2";
    string constant private errMsg3_removeNonexisting = "ERR-A3";
    string constant private errMsg4_removeZero = "ERR-A4";
    string constant private errMsg5_initNonEmpty = "ERR-A5";

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
         *          Each address in the list has an ID from 1 to `addressLists[addressListIndex].length`. 
         */
        uint length;

        /** @dev    `list` maps an address ID to the address itself.
         *          `list` is 1-indexed, not 0-indexed. This is to allow unlisted addresses to map to ID 0.
         */
        mapping(uint => address) list;

        /// @dev    `listInv` maps an address to that address's ID.
        mapping(address => uint) listInv; 
    }

    /// @dev `addresses` is the list of addressLists[addressListIndex]. 
    mapping(uint => AddressList) public addressLists;

    /** @dev    Adds an address to list, binding it to the lowest available ID.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _address The address to add to the list
    function _addAddress(address _address, uint addressListIndex) internal {
        
        require(addressLists[addressListIndex].listInv[_address] == 0, errMsg1_addExisting);
        require(_address != address(0), errMsg2_addZero); 

        /// @dev    `addressLists[addressListIndex].list` is 1-indexed not 0-indexed
        addressLists[addressListIndex].list[addressLists[addressListIndex].length+1] = _address; 
        addressLists[addressListIndex].listInv[_address] = addressLists[addressListIndex].length+1;
        addressLists[addressListIndex].length++;
    }

    /** @dev    Checks if an address can be added to the list by checking the inversions of the require statements in 
     *          _addAddress, then adds it to the list if it can, and does nothing if it cannot.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _address The address to add to the list
    /// @return success | whether the item was added to the list or not
    function _tryToAddAddress(address _address, uint addressListIndex) 
    internal returns (bool success, string memory errMsg) {
        if (!(addressLists[addressListIndex].listInv[_address] == 0))
        {
            return (false, errMsg1_addExisting);
        }
        if (!(_address != address(0))) {
            return (false, errMsg2_addZero);
        }
        _addAddress(_address, addressListIndex);
        return (true, "");
    }

    /** @dev    Conceptually, this function removes an address from the list, unbinds the last address in the list from 
     *          its ID, and rebinds that address to the ID previously bound to the removed address. 
     *          The actual implementation is organized by performing all required operations on `list`, then performing
     *          all required operations on `listInv`.
     */
    /// @param  _address The address to remove from the list
    function _removeAddress(address _address, uint addressListIndex) internal {
        
        require(addressLists[addressListIndex].listInv[_address] != 0, errMsg3_removeNonexisting);
        require(_address != address(0), errMsg4_removeZero); 

        uint removedID = addressLists[addressListIndex].listInv[_address];
        address removedAddress = _address;

        uint lastID = addressLists[addressListIndex].length;
        address lastAddress = addressLists[addressListIndex].list[addressLists[addressListIndex].length];

        /** @dev    Maps the ID of the removed address to the last address in the list, and maps the removed address 
         *          to ID 0. 
         */
        // ID of removedAddress -> lastAddress
        addressLists[addressListIndex].list[removedID] = addressLists[addressListIndex].list[lastID];
        // removedAddress -> ID 0
        delete addressLists[addressListIndex].listInv[removedAddress];

        /** @dev    Maps the last address to the last address in the list, and maps the removed address 
         *          to ID 0.  
         */
        // lastAddress -> removedID
        addressLists[addressListIndex].listInv[lastAddress] = removedID;
        // ID of the end of the list -> zero address
        delete addressLists[addressListIndex].list[lastID];
        
        /// @dev    Finally, decrements the length of the list.
        addressLists[addressListIndex].length--;
    }

    function _tryToRemoveAddress(address _address, uint addressListIndex) 
    internal returns(bool success, string memory errMsg) {
        if (!(addressLists[addressListIndex].listInv[_address] != 0))
        {
            return (false, errMsg3_removeNonexisting);
        }
        if (!(_address != address(0))) {
            return (false, errMsg4_removeZero);
        }
        _removeAddress(_address, addressListIndex);
        return (true, "");
    }
}