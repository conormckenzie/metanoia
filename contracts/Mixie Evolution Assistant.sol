// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./EmergencyPausable.sol";

interface IMixieBaseContract {
    function setStringAttribute(uint nftId_, string memory attributeName, bool checked, string memory value) 
    external;
}

contract MixieEvolutionAssistantV1_0 is 
    ReentrancyGuard, 
    EmergencyPausable
{

    bytes32 public constant LOADER_ROLE = keccak256("LOADER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    mapping(uint => string) loadedImages;

    address constant _mixieBaseContract = 0x27154f3441F191bd3e87D65D8eE2166eef259008;
    IMixieBaseContract mixieBaseContract = IMixieBaseContract(_mixieBaseContract);
    
    constructor() {
        initialize();
    }

    function initialize() public virtual override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        super.initialize();
    }

    function evolveMixie(uint id, bool checked) public nonReentrant whenNotPaused {
        require(
            hasRole(UPDATER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Updater or Admin"
        );
        // update evolution
        mixieBaseContract.setStringAttribute(id, "Evolution", checked, "Adult Form");
        // update image
        mixieBaseContract.setStringAttribute(id, "image", checked, loadedImages[id]);
    }

    function loadMixieImage(uint id, string memory imageUri) public nonReentrant whenNotPaused {
        require(
            hasRole(LOADER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Loader or Admin"
        );
        loadedImages[id] = imageUri;
    }
}