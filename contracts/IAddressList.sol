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


    This is the interface for the Metanoia's Founding Settlers
    List, for use in other contracts.
    
*/

pragma solidity ^0.8.0;

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