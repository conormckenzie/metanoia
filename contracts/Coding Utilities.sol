//SPDX-License-Identifier: MIT

// DO NOT INCLUDE OR INHERIT FROM THIS FILE IN PRODUCTION CONTRACTS

//120 character limit---------------------------------------------------------------------------------------------------
//80 character limit------------------------------------------------------------

pragma solidity ^0.8.0;

contract Utils {


// address public contractGovernor;


//     modifier onlyGovernor() {
//         require(_msgSender() == contractGovernor, 
//             "Permission denied. Only the contract governor can perform that action.");
//             _;
//     }


//     /*  
//     *  @dev Handles checks and effects for minting an existing token. Use for functions that mint existing tokens.
//     */
//     modifier isExistingMint(uint _tokenID, uint _newSupply) {
//         require(exists(_tokenID), 
//             "You have tried to call a mint function on a new token without providing a metadata URI for the token. Please call the correponding function that accepts a URI as a parameter." 
//         );
//         if (_tokenID >= nextUnusedToken) {
//             nextUnusedToken = _tokenID + 1;
//         }
//         totalSupply += _newSupply;
//         _;
//     }


//     /*  
//     *  @dev Handles checks and effects for minting a new token. Use for functions that mint new tokens.
//     */
//     modifier isNewMint(uint _tokenID, uint _newSupply) {
//         require(!exists(_tokenID), 
//             "You have tried to call a mint function on an existing token while providing a new metadata URI. Please call the correponding function without URI as a parameter." 
//         );
//         if (_tokenID >= nextUnusedToken) {
//             nextUnusedToken = _tokenID + 1;
//         }
//         totalSupply += _newSupply;
//         _;
//     }

}