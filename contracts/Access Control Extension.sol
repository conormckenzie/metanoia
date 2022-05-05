// SPDX-License-Identifier: MIT

// this is an extension of OpenZeppelin's AccessControl contract



pragma solidity 0.8.1;

import "@openzeppelin/contracts@4.4.2/access/AccessControl.sol";

abstract contract AccessControlExtension is AccessControl {
    
    //NOT WORKING - DO NOT USE!!
    // If a caller is any of the roles used here, the function is allowed to execute
    // Requiring a caller to have multiple roles to execute a function is
    // acheivable by using multiple requireRole() statments
    // modifier onlyRoles(string[] memory roles) {
    //     bool isAuthorized = false;
    //     string memory errMsg = "Caller does not have any of the following roles (1 is required): {";
    //     for (uint i = 0; i < roles.length; i++) {
    //         bytes32 currentRole = keccak256(abi.encodePacked(roles[i]));
    //         if(hasRole(currentRole, _msgSender())) {
    //             isAuthorized = true;
    //             break;
    //         } else {
    //             string memory _spacing;
    //             if (i == roles.length - 1) {
    //                 _spacing = " }";
    //             } else {
    //                 _spacing = " ,";
    //             }
    //             errMsg = string(abi.encodePacked(
    //                 errMsg, " ", roles[i], _spacing
    //             ));
    //         }
    //     }
    //     require(isAuthorized, errMsg);
    //     _;
    // }
}