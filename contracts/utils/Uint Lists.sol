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
contract UintLists {

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
    struct UintList {

        /** @dev    `length` equals the number of addresses currently in the list. 
         *          Each address in the list has an ID from 1 to `uintLists[addressListIndex].length`. 
         */
        uint length;

        /** @dev    `list` maps an address ID to the address itself.
         *          `list` is 1-indexed, not 0-indexed. This is to allow unlisted addresses to map to ID 0.
         */
        mapping(uint => uint256) list;

        /// @dev    `listInv` maps an address to that address's ID.
        mapping(uint256 => uint) listInv; 
    }

    /// @dev `addresses` is the list of uintLists[addressListIndex]. 
    mapping(uint => UintList) public uintLists;

    /** @dev    Adds an address to list, binding it to the lowest available ID.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _uint The address to add to the list
    function _addUint(uint _uint, uint addressListIndex) internal {
        
        require(uintLists[addressListIndex].listInv[_uint] == 0, errMsg1_addExisting);
        require(_uint != 0, errMsg2_addZero); 

        /// @dev    `uintLists[addressListIndex].list` is 1-indexed not 0-indexed
        uintLists[addressListIndex].list[uintLists[addressListIndex].length+1] = _uint; 
        uintLists[addressListIndex].listInv[_uint] = uintLists[addressListIndex].length+1;
        uintLists[addressListIndex].length++;
    }

    /** @dev    Checks if an address can be added to the list by checking the inversions of the require statements in 
     *          _addUint, then adds it to the list if it can, and does nothing if it cannot.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _uint The address to add to the list
    /// @return success | whether the item was added to the list or not
    function _tryToAddUint(uint _uint, uint addressListIndex) 
    internal returns (bool success, string memory errMsg) {
        if (!(uintLists[addressListIndex].listInv[_uint] == 0))
        {
            return (false, errMsg1_addExisting);
        }
        if (!(_uint != 0)) {
            return (false, errMsg2_addZero);
        }
        _addUint(_uint, addressListIndex);
        return (true, "");
    }

    /** @dev    Conceptually, this function removes an address from the list, unbinds the last address in the list from 
     *          its ID, and rebinds that address to the ID previously bound to the removed address. 
     *          The actual implementation is organized by performing all required operations on `list`, then performing
     *          all required operations on `listInv`.
     */
    /// @param  _uint The address to remove from the list
    function _removeUint(uint _uint, uint addressListIndex) internal {
        
        require(uintLists[addressListIndex].listInv[_uint] != 0, errMsg3_removeNonexisting);
        require(_uint != 0, errMsg4_removeZero); 

        uint removedID = uintLists[addressListIndex].listInv[_uint];
        uint removedUint = _uint;

        uint lastID = uintLists[addressListIndex].length;
        uint lastUint = uintLists[addressListIndex].list[uintLists[addressListIndex].length];

        /** @dev    Maps the ID of the removed address to the last address in the list, and maps the removed address 
         *          to ID 0. 
         */
        // ID of removedUint -> lastUint
        uintLists[addressListIndex].list[removedID] = uintLists[addressListIndex].list[lastID];
        // removedUint -> ID 0
        delete uintLists[addressListIndex].listInv[removedUint];

        /** @dev    Maps the last address to the last address in the list, and maps the removed address 
         *          to ID 0.  
         */
        // lastUint -> removedID
        uintLists[addressListIndex].listInv[lastUint] = removedID;
        // ID of the end of the list -> zero address
        delete uintLists[addressListIndex].list[lastID];
        
        /// @dev    Finally, decrements the length of the list.
        uintLists[addressListIndex].length--;
    }

    function _tryToRemoveUint(uint _uint, uint addressListIndex) 
    internal returns(bool success, string memory errMsg) {
        if (!(uintLists[addressListIndex].listInv[_uint] != 0))
        {
            return (false, errMsg3_removeNonexisting);
        }
        if (!(_uint != 0)) {
            return (false, errMsg4_removeZero);
        }
        _removeUint(_uint, addressListIndex);
        return (true, "");
    }
}