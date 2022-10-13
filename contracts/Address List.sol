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
contract _AddressList {

    string constant private errMsg1_addExisting = "Cannot add address that is already in the list";
    string constant private errMsg2_addZero = "Cannot add the zero address to the list";
    string constant private errMsg3_removeNonexisting = "Cannot remove address that is already not in the list";
    string constant private errMsg4_removeZero = "Cannot remove the zero address from the list";
    string constant private errMsg5_initNonEmpty = "Cannot initialize a list that is not empty";

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

    /** @dev    Adds an address to list, binding it to the lowest available ID.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _address The address to add to the list
    function _addAddress(address _address) internal {
        
        require(addresses.listInv[_address] == 0, errMsg1_addExisting);
        require(_address != address(0), errMsg2_addZero); 

        /// @dev    `addresses.list` is 1-indexed not 0-indexed
        addresses.list[addresses.length+1] = _address; 
        addresses.listInv[_address] = addresses.length+1;
        addresses.length++;
    }

    /** @dev    Checks if an address can be added to the list by checking the inversions of the require statements in 
     *          _addAddress, then adds it to the list if it can, and does nothing if it cannot.
     *          Cannot add to the list the zero address or add address that is already in the list.
     */
    /// @param  _address The address to add to the list
    /// @return success | whether the item was added to the list or not
    function _tryToAddAddress(address _address) internal returns (bool success, string memory errMsg) {
        if (!(addresses.listInv[_address] == 0))
        {
            return (false, errMsg1_addExisting);
        }
        if (!(_address != address(0))) {
            return (false, errMsg2_addZero);
        }
        _addAddress(_address);
        return (true, "");
    }

    /** @dev    Conceptually, this function removes an address from the list, unbinds the last address in the list from 
     *          its ID, and rebinds that address to the ID previously bound to the removed address. 
     *          The actual implementation is organized by performing all required operations on `list`, then performing
     *          all required operations on `listInv`.
     */
    /// @param  _address The address to remove from the list
    function _removeAddress(address _address) internal {
        
        require(addresses.listInv[_address] != 0, errMsg3_removeNonexisting);
        require(_address != address(0), errMsg4_removeZero); 

        uint removedID = addresses.listInv[_address];
        address removedAddress = _address;

        uint lastID = addresses.length;
        address lastAddress = addresses.list[addresses.length];

        /** @dev    Maps the ID of the removed address to the last address in the list, and maps the removed address 
         *          to ID 0. 
         */
        // ID of removedAddress -> lastAddress
        addresses.list[removedID] = addresses.list[lastID];
        // removedAddress -> ID 0
        delete addresses.listInv[removedAddress];

        /** @dev    Maps the last address to the last address in the list, and maps the removed address 
         *          to ID 0.  
         */
        // lastAddress -> removedID
        addresses.listInv[lastAddress] = removedID;
        // ID of the end of the list -> zero address
        delete addresses.list[lastID];
        
        /// @dev    Finally, decrements the length of the list.
        addresses.length--;
    }

    function _tryToRemoveAddress(address _address) internal returns(bool success, string memory errMsg) {
        if (!(addresses.listInv[_address] != 0))
        {
            return (false, errMsg3_removeNonexisting);
        }
        if (!(_address != address(0))) {
            return (false, errMsg4_removeZero);
        }
        _removeAddress(_address);
        // console.log("[SOL] CP6: lastAddress=%s, removedID=%s", 
        //     addresses.list[addresses.length], addresses.listInv[_address]
        // );
        return (true, "");
    }

    /** @dev    Initializes the address list with a set pre-approved list of addresses. 
    *           Ignores adding any addresses that already exists in the list or is invalid.
    *           the ID of the former last address maps to the zero address. 
    *           
    */
    function _initList() internal {
        require(addresses.length == 0, errMsg5_initNonEmpty);
        _tryToAddAddress(0xEcb074B04151fFA0CEdBD070e84D62673750D2e8);
        _tryToAddAddress(0x89046fBB6538A3d3DfA94b04F577Ed630cC99C06);
        _tryToAddAddress(0x8cFe3482Eb04819ED5FaC1265D7b1EC0701887dA);
        _tryToAddAddress(0xa22CcF5AbFa599ed1e434D480469784e95F8d9bf);
        _tryToAddAddress(0x50Ad91E62958C5715F652Da531aC1dedf315f2C9);
        _tryToAddAddress(0x83226edb655488522af57Fb94deCF77c05bd324c);
        _tryToAddAddress(0x019A2e8c754Fb4629631eAe0125305f94CE6aC0a);
        _tryToAddAddress(0xd7B9260fEdb5800B74e0a3BFF596c1e3A63AA834);

    }

    // testing functions included in the Address List Testing file
    // /// @dev    Getters for the underlying list variable. Useful for testing.
    // function addresses_length() public view returns(uint) {
    //     return addresses.length;
    // }
    // function addresses_list(uint id) public view returns(address) {
    //     return addresses.list[id];
    // }
    // function addresses_listInv(address _address) public view returns(uint) {
    //     return addresses.listInv[_address];
    // }
}