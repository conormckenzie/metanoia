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


    This is the contract which hosts the list of privileged
    buyers for the Founding Citizen NFT Sale.
*/


import "@openzeppelin/contracts/access/AccessControl.sol";

pragma solidity 0.8.4;

contract PrivilegedListStorage is AccessControl {

    bytes32 public constant ADDRESS_MANAGER_ROLE = keccak256("ADDRESS_MANAGER_ROLE");
    bytes32 public constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER_ROLE");
    bytes32 public constant COUPON_USER_ROLE = keccak256("COUPON_USER_ROLE");

    struct Coupon {
        uint discountRate;
        uint numberOfUses;
    }

    struct idList {
        uint ids;
    }

    struct CouponList { // each address in addressList has one couponList
        uint length;
        mapping(uint/*id*/ => Coupon) coupons; 
    }

    struct AddressList {
        uint length;
        mapping(uint/*id*/ => address) addresses; // <addresses> is enumerable, 1-indexed
        mapping(address => uint/*id*/) ids; 
        mapping(uint/*id*/ => CouponList) couponLists;
        // <ids> tracks the same info as <addresses>, but is inverted (allows address to be used as a key)
    }
    AddressList public addressList;

    function idOf(address address_) public view returns(uint) {
        return addressList.ids[address_];
    }

    function couponListLength(address address_) public view returns(uint) {
        return addressList.couponLists[idOf(address_)].length;
    }

    function addressExists(address address_) public view returns(bool) {
        return (idOf(address_) == 0);
    }

    function addressHasCoupon(address address_) public view returns(bool) {
        return (addressList.couponLists[idOf(address_)].length == 0);
    }

    function addressHasCoupon(address address_, uint discountRate) public view returns(bool) {
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (addressList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate) 
            {
                return true;
            }
        }
        return false;
    }

    function addAddress(address address_) public {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Approved Role: Address Manager, Coupon Manager, Coupon User, or Admin"
        );
        addressList.length++;
        addressList.addresses[addressList.length] = address_; //<addressList.addresses> is 1-indexed not 0-indexed
        addressList.ids[address_] = addressList.length;
    }

    /*
    *  @dev Removes <address_> from <addressList> and moves the last address in
    *       <addressList.addresses> into its spot. 
    *       Updates <addressList.ids> accordingly.  
    */
    function removeAddress(address address_) public {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Address Manager or Admin"
        );
        
        uint _toRemove1 = idOf(address_);
        address _toRemove2 = address_;

        uint _toMove1 = addressList.length;
        address _toMove2 = addressList.addresses[addressList.length];

        addressList.addresses[_toRemove1] = addressList.addresses[_toMove1];
        delete addressList.addresses[_toMove1];

        addressList.ids[_toRemove2] = addressList.ids[_toMove2];
        delete addressList.ids[_toMove2];
        
        addressList.length--;
    }

    function addCoupon(address address_, uint discountRate, uint numberOfUses) public {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager or Admin"
        );
        if (!addressExists(address_)) {
            addAddress(address_);
        }
        //currentCouponList = addressList.couponLists[idOf(address_)]
        addressList.couponLists[idOf(address_)].length++;
        //currentCoupon = addressList.couponLists[idOf(address_)].coupons[currentCouponList.length]
        addressList.couponLists[idOf(address_)]
            .coupons[couponListLength(address_)]
                .discountRate = discountRate;
        addressList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .numberOfUses = numberOfUses;
    }

    function removeCoupon(address address_, uint id) public {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        addressList.couponLists[idOf(address_)].coupons[id] = 
            addressList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        delete addressList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        addressList.couponLists[idOf(address_)].length--;
    }

    function _reduceCouponUses(address address_, uint id, uint numberOfUses) internal {
        bool condition = (addressList.couponLists[idOf(address_)].coupons[id].numberOfUses >= numberOfUses);
        string memory errorMsg = string(abi.encodePacked(
            "Cannot reduce coupon uses by more than the number of uses for this coupon: ", 
            addressList.couponLists[idOf(address_)].coupons[id].numberOfUses));
        require(condition, errorMsg);
        addressList.couponLists[idOf(address_)].coupons[id].numberOfUses -= numberOfUses;
        if (addressList.couponLists[idOf(address_)].coupons[id].numberOfUses <= 0) {
            removeCoupon(address_, id);
        }
    }

    function reduceCouponUses(address address_, uint discountRate, uint numberOfUses) public {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (addressList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate) 
            {
                _reduceCouponUses(address_, i, numberOfUses);
                break;
            }
        }
    }

    function useCoupon(address address_, uint discountRate) public {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        reduceCouponUses(address_, discountRate, 1);
    }

    function _initList() internal {
        addressList.length = 0;
        addAddress(0xc0ffee254729296a45a3885639AC7E10F9d54979);
        addAddress(0x59eeD72447F2B0418b0fe44C0FCdf15AAFfa1f77);
        addAddress(0xCb172d8fA7b46b53A6b0BDACbC5521b315D1d3F7);
        addAddress(0x5061b6b8B572776Cff3fC2AdA4871523A8aCA1E4);
        addAddress(0xff2710dF4D906414C01726f049bEb5063929DaA8);
        addAddress(0xb3c8801aF1E17a4D596E7678C1548094C872AE0D);

    }
}