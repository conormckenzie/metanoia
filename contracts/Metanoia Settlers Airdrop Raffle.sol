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


    This is the contract that hosts airdrops and raffles for 
    Metanoia's Founding Settlers.

*/

import "./ERC1155MultiUri.sol";
import "./IAddressList.sol";
import "./EmergencyPausable.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

pragma solidity 0.8.4;

/// @title  Founding Settlers Airdrops & Raffles
/// @author Conor McKenzie
/** @notice This contract mints ERC-1155 tokens via airdrop or raffle to addresses in the Founding Settlers List.  
 *          
 *          You can use this contract to transfer your any tokens you own to another address or do any other action 
 *          with the tokens that is supported by the ERC-1155 standard.
 */
/** @dev    All non-view non-pure public functions in this contract other than those from Metanoia's ERC-1155-MultiURI 
 *          contract (which this contract inherits from) are restricted to be accessible only by the owner.
 *
 *          The Founding Settlers List may exceed 100 addresses after minting, by use of the `addAddress` function. 
 */
contract SettlersAirDropRaffle is ERC1155MultiUri, EmergencyPausable {
    address public extrasHolder = 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78;
    IAddressList public MFSList;

    string public name;
    string public symbol;
    
    /*  
    *  @dev totalSupply accumulates the total supply of ALL tokens from this contract, not each token individually.
    *       Individual token supplies can be retreived by calling the "totalSupply(<tokenID>)" getter.
    */
    uint public totalSupply;

    uint public nextUnusedToken;


    mapping (uint => uint) _pseudoRandomNumbers;
    bool _randomsAreFresh;
    uint _internalSeed; //prevents a user-given seed from producing identical pseudorandoms in subsequent runs. 

    /*  
    *  @dev Handles checks and effects for minting an existing token. Use for functions that mint existing tokens.
    */
    modifier isExistingMint(uint _tokenID, uint _newSupply) {
        require(exists(_tokenID), 
        // solhint-disable-next-line max-line-length
            "You have tried to call a mint function on a new token without providing a metadata URI for the token. Please call the correponding function that accepts a URI as a parameter." 
        );
        if (_tokenID >= nextUnusedToken) {
            nextUnusedToken = _tokenID + 1;
        }
        totalSupply += _newSupply;
        _;
    }

    /*  
    *  @dev Handles checks and effects for minting a new token. Use for functions that mint new tokens.
    */
    modifier isNewMint(uint _tokenID, uint _newSupply) {
        require(!exists(_tokenID), 
        // solhint-disable-next-line max-line-length
            "You have tried to call a mint function on an existing token while providing a new metadata URI. Please call the correponding function without URI as a parameter." 
        );
        if (_tokenID >= nextUnusedToken) {
            nextUnusedToken = _tokenID + 1;
        }
        totalSupply += _newSupply;
        _;
    }

    constructor() ERC1155("URI not applicable: Using ERC1155MultiURI") {
        
        name = "Metanoia Founding Settlers Collection";
        symbol = "MFS Collection";

        //MFSList = 0x...;
    }

    /*
    *  @dev Gets one or more distinct pseudorandom numbers _in the range [1,_max] based on a seed provided by the 
    *           function caller. 
    *       WARNING: This is not suitable for use as a truly random number generator - it is only suitable as a  
    *           method to morph a seed generated outside the blockchain to a number or set of numbers usable
    *           on the blockchain.  
    *       CAUTION: The seed chosen should be large to reduce the seed's prior predictability and prevent small 
    *           obvious candidate seeds such as 0,1,10,22,100,123,etc. being used.
    *       NOTE: This uses the Knuth algorithm to select distinct pseudorandom numbers.  
    *           Ref: https://stackoverflow.com/questions/1608181/unique-random-number-generation-_in-an-integer-array
    */
    function _getDistinctPseudoRandomNumbers(uint _seed, uint _quantity, uint _max) internal {
        require(_quantity < _max, 
            "Cannot return more pseudorandoms than exist in the range. Please ensure _quantity < _max.");
        uint N = _max;
        uint M = _quantity;
        uint _in;
        uint _im = 0;
        for (_in = 0; _in < N && _im < M; _in++) {
            uint _rn = N - _in;
            uint _rm = M - _im;
            if (_rand(_seed, _in) % _rn < _rm) {
                _pseudoRandomNumbers[_im++] = _in + 1;
            }
        }
        require(_im == M, "error in Knuth algorithm implementation");
        assert(_im == M);
        _randomsAreFresh = true;
    }

    /*
    *  @dev Morphs <_seed>, <_i>, and <_internalSeed> into a new value that cannot be influenced by miners.
    */
    function _rand(uint _seed, uint _i) internal returns(uint) {
        require(_seed >= 100000, "seed number must be at least 6 digits long");
        uint _random = uint(
            keccak256(abi.encodePacked(_i, _seed, _internalSeed)));
        _internalSeed = _random;
        return _random;
    }

    /*
    *  @dev Clears <_pseudoRandomNumbers> so that they are not accidentally used more than once.
    */
    function _resetRandomNumbers(uint _quantity) internal {
        for (uint _i = 0; _i < _quantity; _i++) {
            delete _pseudoRandomNumbers[_i];
        }
        _randomsAreFresh = false;
    }

    /*
    *  @dev See file "./ERC1155MultiURI.sol"
    */
    function sendItems(address to, uint tokenID, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeTransferFrom(extrasHolder, to, tokenID, amount, "");
    }

    /*
    *  @dev See file "./ERC1155MultiURI.sol"
    */
    function sendItem(address to, uint tokenID) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sendItems(to, tokenID, 1);
    }

    /*
    *  @dev Helper function for minting by airdrop with or without URI
    */
    function _mintByAirdrop(uint tokenID, uint amountPerRecipient, string memory newuri) 
    internal {
        for (uint _i = 1; _i <= MFSList.getMFS_length(); _i++) {
            if(exists(tokenID)) {
                _mintWithoutURI(MFSList.getMFS_list(_i), tokenID, amountPerRecipient, "");
            }
            else {
                _mintWithURI(MFSList.getMFS_list(_i), tokenID, amountPerRecipient, "", newuri);
            }
        }
    }

    /*
    *  @dev Mints an existing token to all addresses() in the Founding Settler's List.
    */
    function mintExistingByAirdrop(uint tokenID, uint amountPerRecipient) 
    public onlyRole(DEFAULT_ADMIN_ROLE) isExistingMint(tokenID, MFSList.getMFS_length() * amountPerRecipient) {
        _mintByAirdrop(tokenID, amountPerRecipient, "");
    }

    /*
    *  @dev Mints a new token to all addresses() in the Founding Settler's List.
    */
    function mintNewByAirdrop(uint tokenID, uint amountPerRecipient, string memory newuri) 
    public onlyRole(DEFAULT_ADMIN_ROLE) isNewMint(tokenID, MFSList.getMFS_length() * amountPerRecipient) {
        _mintByAirdrop(tokenID, amountPerRecipient, newuri);
    }

    /*
    *  @dev Helper function for minting by raffle with or without URI
    */
    function _mintByRaffle(
        uint tokenID, uint amountPerWinner, uint numberOfWinners, uint randomSeed, string memory newuri
    ) internal { 
        _getDistinctPseudoRandomNumbers(randomSeed, numberOfWinners, MFSList.getMFS_length());
        require(_randomsAreFresh, "randoms are stale. Please get new random numbers");
        for (uint _i = 0; _i < numberOfWinners; _i++) {
            if(exists(tokenID)) {
                _mintWithoutURI(MFSList.getMFS_list(_pseudoRandomNumbers[_i]), tokenID, amountPerWinner, "");
            }
            else {
                _mintWithURI(MFSList.getMFS_list(_pseudoRandomNumbers[_i]), tokenID, amountPerWinner, "", newuri);
            }
        }
        _resetRandomNumbers(numberOfWinners);
    }

    /*
    *  @dev Mints an existing token to a random set of addresses() in the Founding Settler's List.
    */
    function mintByRaffle(
        uint tokenID, 
        uint amountPerWinner, 
        uint numberOfWinners, 
        uint randomSeed
    ) public onlyRole(DEFAULT_ADMIN_ROLE) isExistingMint(tokenID, amountPerWinner * numberOfWinners) { 
        _mintByRaffle(tokenID, amountPerWinner, numberOfWinners, randomSeed, "");
    }

    /*
    *  @dev Mints a new token to a random set of addresses() in the Founding Settler's List.
    */
    function mintNewByRaffle(
        uint tokenID, uint amountPerWinner, uint numberOfWinners, uint randomSeed, string memory newuri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) isNewMint(tokenID, amountPerWinner * numberOfWinners) { 
        _mintByRaffle(tokenID, amountPerWinner, numberOfWinners, randomSeed, newuri);
    }

    /*
    *  @dev Mints an existing token to the <extrasHolder> holding address.
    */
    function mintToExtrasHolder(uint tokenID, uint amount) 
    public onlyRole(DEFAULT_ADMIN_ROLE) isExistingMint(tokenID, amount) {
        _mintWithoutURI(extrasHolder, tokenID, amount, "");
    }

    /*
    *  @dev Mints a new token to the <extrasHolder> holding address.
    */
    function mintNewToExtrasHolder(
        uint tokenID, uint amount, string memory newuri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) isNewMint(tokenID, amount) {
        _mintWithURI(extrasHolder, tokenID, amount, "", newuri);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}