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


    This is a supporting contract which handles emergency pausing of functions in case of exploits or bugs.
*/


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

pragma solidity 0.8.4;

contract EmergencyPausable is AccessControl, Pausable, Initializable {

    event emergencyPaused(address indexed msgSender);

    mapping (string => bytes32) public bytesToRoles;
    bytes32 public constant EMERGENCY_PAUSER_ROLE = keccak256("EMERGENCY_PAUSER_ROLE");

    function initialize() public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);
        bytesToRoles["DEFAULT_ADMIN_ROLE"] = DEFAULT_ADMIN_ROLE;
        bytesToRoles["EMERGENCY_PAUSER_ROLE"] = EMERGENCY_PAUSER_ROLE;
    }
    
    function emergencyPause() public whenNotPaused() {
        require(
            hasRole(EMERGENCY_PAUSER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only admin or designated emergency pauser can emergency pause"
        );
        emit emergencyPaused(_msgSender());
        _pause();
    }

    function unpause() public whenPaused() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only admin can unpause"
        );
        // already emits an "unpaused" event
        _unpause();
    }
}