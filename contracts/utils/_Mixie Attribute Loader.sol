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
}

contract _MixieAttributeLoaderV1_1 is Ownable {

    

    // ALL testing flags should be FALSE when deploying
    bool constant testing1 = true; // toggles use of testing (true) or real (false) name, symbol, and contractUri.
    bool constant testing2 = true; // toggles use of testing (true) or real (false) description, image, and animation.
    bool constant testing3 = true; // toggles use of testing (true) or real (false) Mixie egg contract.

    // this particular address is for testing only
    MixieBase public mixieContract = MixieBase(0x692112C8c7446887D9ffaE282bc5ADF874006179);

    mapping(address => bool) _loaded;

    function load(address mixieContract_) public onlyOwner {
        mixieContract = MixieBase(mixieContract_);
        // only can load once
        require(!_loaded[mixieContract_]);
        _loaded[mixieContract_] = true;
        mixieContract.registerAttribute(
            "name",
            "string",
            TypeConversions.StringToBytes(testing1 ? "Test Mixie" : "Mixie")
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("name"), true);
        mixieContract.registerAttribute(
            "description",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "test description" : "Metanoia is an alternative nation native to web3, where everyone will be able to gain access and own a slice of the power and economic opportunities previously only made available to the political elite, the well connected or the rich. \n\nThe Founding Citizen NFTs, represented in the form of Mixies, allows holders to get special perks and privileges from Metanoia. \nLearn more about Founding Citizen NFT benefits: https://medium.com/metanoia-country/founding-citizen-nft-sale-b7e1524a5e69")
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("description"), true);
        mixieContract.registerAttribute(
            "image",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "https://www.andina-ingham.co.uk/wp-content/uploads/2019/09/miguel-andrade-nAOZCYcLND8-unsplash_pineapple.jpg" 
            : "{TBD Arweave}")
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("image"), true);
        mixieContract.registerAttribute(
            "external_url",
            "string",
            TypeConversions.StringToBytes("https://metanoia.country/")
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("external_url"), true);
        mixieContract.registerAttribute(
            "animation_url",
            "string",
            // solhint-disable-next-line max-line-length
            TypeConversions.StringToBytes(testing2 ? "https://565nmzdax6zdlmfb2zqukkzwpmqvdkagtbsqtubrxm6s24fhn6fq.arweave.net/77rWZGC_sjWwodZhRSs2eyFRqAaYZQnQMbs9LXCnb4s" 
            : "{TBD Arweave}")
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("animation_url"), true);
        mixieContract.registerAttribute(
            "fee_recipient",
            "address",
            TypeConversions.addressToBytes(0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d)
        );
        mixieContract.setUriVisibility(mixieContract.getAttributeIdFromName("name"), false);
    }
}