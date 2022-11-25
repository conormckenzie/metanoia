// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TypeConversions.sol";

interface MixieBase {
    function registerAttribute(
        string memory attributeName, 
        string memory attributeType, 
        bytes memory defaultValue
    ) external;
    function getAttributeIdFromName(string memory attributeName) external view returns(uint);
    function setUriVisibility(uint attributeId, bool visible) external;
    function isRegistered(uint attributeId) external view returns(bool);
}

contract _MixieAttributeLoaderLiveV1_6 is Ownable {

    

    // ALL testing flags should be FALSE when deploying
    bool constant testing1 = false; // toggles use of testing (true) or real (false) name, symbol, and contractUri.
    bool constant testing2 = false; // toggles use of testing (true) or real (false) description, image, and animation.
    bool constant testing3 = false; // toggles use of testing (true) or real (false) Mixie egg contract.

    mapping(address => bool) _loaded;

    function load(address mixieContract_) public onlyOwner {
        MixieBase mixieContract = MixieBase(mixieContract_);
        string memory currentName;
        // only can load once
        require(!_loaded[mixieContract_]);
        _loaded[mixieContract_] = true;

        // PRESET ATTRIBUTES

        currentName = "name";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes(testing1 ? "Test Mixie" : "Mixie")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "description";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                // solhint-disable-next-line max-line-length
                TypeConversions.stringToBytes(testing2 ? "test description" : "Metanoia is an alternative nation native to web3, where everyone will be able to gain access and own a slice of the power and economic opportunities previously only made available to the political elite, the well connected or the rich. \n\nThe Founding Citizen NFTs, represented in the form of Mixies, allows holders to get special perks and privileges from Metanoia. \nLearn more about Founding Citizen NFT benefits: https://medium.com/metanoia-country/founding-citizen-nft-sale-b7e1524a5e69")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "image";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                // solhint-disable-next-line max-line-length
                TypeConversions.stringToBytes(testing2 ? "https://www.andina-ingham.co.uk/wp-content/uploads/2019/09/miguel-andrade-nAOZCYcLND8-unsplash_pineapple.jpg" 
                : "{TBD Arweave}")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "external_url";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("https://metanoia.country/")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "animation_url";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                // solhint-disable-next-line max-line-length
                TypeConversions.stringToBytes(testing2 ? "https://565nmzdax6zdlmfb2zqukkzwpmqvdkagtbsqtubrxm6s24fhn6fq.arweave.net/77rWZGC_sjWwodZhRSs2eyFRqAaYZQnQMbs9LXCnb4s" 
                : "")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "fee_recipient";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "address",
                TypeConversions.addressToBytes(0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d)
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }

        // CUSTOM ATTRIBUTES:

        // visible (1):

        currentName = "Category";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Category Item";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Type";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Palette";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Suit";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Fluff";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Ears";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Eyes";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Nose";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Mouth";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Cheeks";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Tail";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }

        // invisible - body

        currentName = "Torso";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "uint",
                TypeConversions.uintToBytes(0)
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "Head";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "uint",
                TypeConversions.uintToBytes(0)
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "Left Arm";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "uint",
                TypeConversions.uintToBytes(0)
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "Right Arm";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "uint",
                TypeConversions.uintToBytes(0)
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }

        // visible (2)

        currentName = "Accessory";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Wings";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        currentName = "Background Effect";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
        
        // invisible - clouds

        currentName = "Foreground Cloud";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "Background";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }
        currentName = "Background Cloud";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), false);
        }

        // EXTRA

        currentName = "Evolution";
        if (mixieContract.getAttributeIdFromName(currentName) == 0) {
            mixieContract.registerAttribute(
                currentName,
                "string",
                TypeConversions.stringToBytes("Not yet determined")
            );
            mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName(currentName), true);
        }
    }
}