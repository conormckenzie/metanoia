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


    This is the contract responsible for the minting and
    storage of the Founding Citizen NFTs (Mixies).

*/

import "./ERC2981/ERC2981ContractWideRoyalties.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; 
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./EmergencyPausable.sol";

// Ownable is only used to get OpenSea to recognize ownership, so that the off-chain details of the collection 
// can be filled out 
import "@openzeppelin/contracts/access/Ownable.sol";



pragma solidity 0.8.4;

contract MixieBase is 
ERC1155Supply, ERC2981ContractWideRoyalties, ReentrancyGuard, EmergencyPausable, Ownable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    // IN PRODUCTION, ALL TESTING TOGGLES SHOULD BE FALSE
    bool constant testing1 = true; 
    bool constant testing2 = true; 

    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = testing2 ? "" : "{TBD}";

     /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public constant name = testing2 ? "Test Metanoia Mixie" : " Metanoia Mixie"; 
    string public symbol = testing2 ? "MIXIE TEST" : "METANOIA MIXIE"; 

    // solhint-disable-next-line max-line-length
    string constant constructorUri = testing2 ? "" : "{TBD}";

    function initialize() public override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);
        _setRoyalties(royaltyRecipient, royaltyFee);

        super.initialize();
    }
    
    constructor() ERC1155(constructorUri) {
        initialize();
    }

    /** @notice Returns the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     */
    /// @dev    This method is separate from ERC2981 and does not use the on-chain variables that RoyaltyInfo uses.
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

        /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155,ERC2981Base, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}