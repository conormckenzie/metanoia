//SPDX-License-Identifier: MIT

/* RELEASE NOTES:
    This contract is is only to be used for the initial Metanoia Settler's NFT
    mint - it is a cheaper and simpler alternative to using Chainlink. This is 
    fine for the initial Metanoia Settler's NFT mint since that contract will 
    only be used to mint tickets once, on creation of the contract.   
    
    This contract may be used in deployments with other contracts related to
    the Metanoia Founding Settlers, but in each deployment the lists will not
    be linked with lists in other deployments, so it is suggested to limit
    the number of active deployments which use this list to 1, not including
    the initial Metanoia Settler's NFT mint.
*/

pragma solidity 0.8.1;

contract FoundingSettlersList {

    struct AddressList {
        uint length;
        mapping(uint => address) list; // <list> is enumerable, 1-indexed
        mapping(address => uint) listInv; 
        // <listInv> tracks the same info as <list>, but is inverted (allows address to be used as a key)
    }
    AddressList public addresses;

    function _addAddress(address _address) internal {
        addresses.list[addresses.length+1] = _address; //<addresses.list> is 1-indexed not 0-indexed
        addresses.listInv[_address] = addresses.length+1;
        addresses.length++;
    }

    /*
    *  @dev Removes <_address> from <addresses> and moves the last address in
    *       <addresses.list> into its spot. 
    *       Updates <addresses.listInv> accordingly.  
    */
    function _removeAddress(address _address) internal {
        
        uint _toRemove1 = addresses.listInv[_address];
        address _toRemove2 = _address;

        uint _toMove1 = addresses.length;
        address _toMove2 = addresses.list[addresses.length];

        addresses.list[_toRemove1] = addresses.list[_toMove1];
        delete addresses.list[_toMove1];

        addresses.listInv[_toRemove2] = addresses.listInv[_toMove2];
        delete addresses.listInv[_toMove2];
        
        addresses.length--;
    }

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