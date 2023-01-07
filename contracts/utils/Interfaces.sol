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


    This file contains interfaces for use in other Metanoia contracts.
*/

pragma solidity ^0.8.0;

/// ----- MIXIE SALE ----- ///

interface IMintStorage {
    function preLoadURIs(uint[] memory ids, string[] memory uris) external;
    function mintNextNftToAddress(address to) external;
    function getNextUnusedToken() external view returns(uint);
    function getMaxSupply() external pure returns(uint);
}

interface IPrivilegedListStorage {
    function removeAddress(address address_) external;
    function addCoupon(address address_, uint discountRate, uint numberOfUses) external;
    function useCoupon(address address_, uint discountRate) external;
    function addressHasCoupon(address address_, uint discountRate) external view returns(bool);
}

interface IUsdcStorage {
    function getUsdcBalance(address address_) external view returns(uint);
    function transferUsdcBalance(address from, address to, uint amount) external;
    function increaseUsdcBalance(address address_, uint amount) external;
    function decreaseUsdcBalance(address address_, uint amount) external;
}

/// @title  Founding Settlers List Interface
/// @author Conor McKenzie
/** @notice This interface allows view-only access to the Founding Settlers List.
 */
/** @dev    Interface to get all attributes from the `AddressList` struct which comprises the Founding Settlers List. 
 *          Each of this interface's functions is view-only and takes constant time.
 *          More info can be found in source code for the Founding Settlers Tickets NFT mint & storage contract.
 */
interface IAddressList {
    function getMFS_length() external view returns(uint length);
    function getMFS_list(uint ID) external view returns(address FoundingSettlerAddress);
    function getMFS_listInv(address FoundingSettlerAddress) external view returns(uint addressID);
}