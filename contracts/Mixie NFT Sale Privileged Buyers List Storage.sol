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

import "./EmergencyPausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

pragma solidity 0.8.4;

contract PrivilegedListStorage is AccessControl, EmergencyPausable, Initializable {

    bytes32 public constant ADDRESS_MANAGER_ROLE = keccak256("ADDRESS_MANAGER_ROLE");
    bytes32 public constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER_ROLE");
    bytes32 public constant COUPON_USER_ROLE = keccak256("COUPON_USER_ROLE");

    struct Coupon {
        // coupon types - 1: regular discount, 2: bulk buy
        uint couponType;
        uint numberOfUses; // applies to coupon types 1, 2

        uint discountRate; // applies to coupon type 1
        
        uint numberOfMixies; // applies to coupon type 2
        uint totalPrice; // applies to coupon type 2
    }

    // struct idList {
    //     uint ids;
    // }

    struct CouponList { // each address in addressList has one couponList
    // WARNING: must be iterated over to show the user's existing coupons
        uint length;
        mapping(uint/*id*/ => Coupon) coupons; 
    }

    struct CouponListList {
        uint length;
        mapping(uint/*id*/ => address) addresses; // <addresses> is enumerable, 1-indexed
        mapping(address => uint/*id*/) ids; 
        mapping(uint/*id*/ => CouponList) couponLists;
        // <ids> tracks the same info as <addresses>, but is inverted (allows address to be used as a key)
    }
    CouponListList public couponListList;

    function idOf(address address_) public view returns(uint) {
        return couponListList.ids[address_];
    }

    function couponListLength(address address_) public view returns(uint) {
        return couponListList.couponLists[idOf(address_)].length;
    }

    function addressExists(address address_) public view returns(bool) {
        return (idOf(address_) == 0);
    }

    function addressHasCoupon(address address_) public view returns(bool) {
        return (couponListList.couponLists[idOf(address_)].length == 0);
    }

    function addressHasType1Coupon(address address_, uint discountRate, uint mode) public view returns(bool) {
        require(mode >= 1 && mode <= 2, "Mixie NFT Sale Privileged Boyers List: addressHasType1Coupon: invalid mode");
        if (mode == 1) { // discount rate provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 1 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate
                ) {
                    return true;
                }
            }
            return false;
        }
        if (mode == 2) { // discount rate not provided   
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 1
                ) {
                    return true;
                }
            }
            return false;
        }
        revert("Mixie NFT Sale Privileged Boyers List: addressHasType1Coupon: invalid mode");
    }

    function addressHasType2Coupon(address address_, uint numberOfMixies, uint totalPrice, uint mode) 
    public view returns(bool) {
        require(mode >= 1 && mode <= 4, "Mixie NFT Sale Privileged Boyers List: addressHasType2Coupon: invalid mode");
        if (mode == 1) { // both numberOfMixies and totalPrice are provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies &&
                    couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
                ) {
                    return true;
                }
            }
            return false;
        }
        if (mode == 2) { // only numberOfMixies is provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies
                ) {
                    return true;
                }
            }
            return false;
        }
        if (mode == 3) { // only totalPrice is provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
                ) {
                    return true;
                }
            }
            return false;
        }
        if (mode == 4) { // neither numberOfMixies nor totalPrice is provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2
                ) {
                    return true;
                }
            }
            return false;
        }
        revert("Mixie NFT Sale Privileged Boyers List: addressHasType2Coupon: invalid mode");
    }

    function addAddress(address address_) public whenNotPaused {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Approved Role: Address Manager, Coupon Manager, Coupon User, or Admin"
        );
        couponListList.length++;
        couponListList.addresses[couponListList.length] = address_; //<addressList.addresses> is 1-indexed not 0-indexed
        couponListList.ids[address_] = couponListList.length;
    }

    /*
    *  @dev Removes <address_> from <addressList> and moves the last address in
    *       <addressList.addresses> into its spot. 
    *       Updates <addressList.ids> accordingly.  
    */
    function removeAddress(address address_) public whenNotPaused {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Address Manager or Admin"
        );
        
        uint _toRemove1 = idOf(address_);
        address _toRemove2 = address_;

        uint _toMove1 = couponListList.length;
        address _toMove2 = couponListList.addresses[couponListList.length];

        couponListList.addresses[_toRemove1] = couponListList.addresses[_toMove1];
        delete couponListList.addresses[_toMove1];

        couponListList.ids[_toRemove2] = couponListList.ids[_toMove2];
        delete couponListList.ids[_toMove2];
        
        couponListList.length--;
    }

    function addCoupon(
        address address_, 
        uint couponType, 
        uint discountRate,
        uint numberOfMixies, 
        uint totalPrice,
        uint numberOfUses
    ) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager or Admin"
        );
        if (!addressExists(address_)) {
            addAddress(address_);
        }
        //currentCouponList = addressList.couponLists[idOf(address_)]
        couponListList.couponLists[idOf(address_)].length++;
        //currentCoupon = addressList.couponLists[idOf(address_)].coupons[currentCouponList.length]
        couponListList.couponLists[idOf(address_)]
            .coupons[couponListLength(address_)]
                .discountRate = discountRate;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .numberOfUses = numberOfUses;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .couponType = couponType;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .numberOfMixies = numberOfMixies;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .totalPrice = totalPrice;
    }

    function removeCoupon(address address_, uint id) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        couponListList.couponLists[idOf(address_)].coupons[id] = 
            couponListList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        delete couponListList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        couponListList.couponLists[idOf(address_)].length--;
    }

    function _reduceCouponUses(address address_, uint id, uint numberOfUses) internal whenNotPaused {
        bool condition = (couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses >= numberOfUses);
        string memory errorMsg = string(abi.encodePacked(
            "Cannot reduce coupon uses by more than the number of uses for this coupon: ", 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses));
        require(condition, errorMsg);
        couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses -= numberOfUses;
        if (couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses <= 0) {
            removeCoupon(address_, id);
        }
    }

    function reduceType1CouponUses(address address_, uint discountRate, uint numberOfUses) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (couponListList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate) 
            {
                _reduceCouponUses(address_, i, numberOfUses);
                break;
            }
        }
    }

    function reduceType2CouponUses(
        address address_, 
        uint numberOfMixies, 
        uint totalPrice, 
        uint numberOfUses) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (
                couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies &&
                couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
            ) {
                _reduceCouponUses(address_, i, numberOfUses);
                break;
            }
        }
    }

    function useType1Coupon(address address_, uint discountRate) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        reduceType1CouponUses(address_, discountRate, 1);
    }

    function useType2Coupon(address address_, uint numberOfMixies, uint totalPrice) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        reduceType2CouponUses(address_, numberOfMixies, totalPrice, 1);
    }

    function useCoupon(
        address address_, 
        uint couponType, 
        uint discountRate,
        uint numberOfMixies, 
        uint totalPrice
    ) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager, Coupon User, or Admin"
        );
        if (couponType == 1) {
            reduceType1CouponUses(address_, discountRate, 1);
        }
        if (couponType == 2) {
            reduceType2CouponUses(address_, numberOfMixies, totalPrice, 1);
        }
        revert("Mixie NFT Sale Privileged Boyers List: useCoupon: invalid couponType");
    }

    //probably should change this to use public only-once initialization.

    function initialize() public initializer {
        couponListList.length = 0;
        addAddress(0xc0ffee254729296a45a3885639AC7E10F9d54979);
        addAddress(0x59eeD72447F2B0418b0fe44C0FCdf15AAFfa1f77);
        addAddress(0xCb172d8fA7b46b53A6b0BDACbC5521b315D1d3F7);
        addAddress(0x5061b6b8B572776Cff3fC2AdA4871523A8aCA1E4);
        addAddress(0xff2710dF4D906414C01726f049bEb5063929DaA8);
        addAddress(0xb3c8801aF1E17a4D596E7678C1548094C872AE0D);

    }
}