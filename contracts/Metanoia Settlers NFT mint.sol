/*
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

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


    This is the contract that mints the collection of 
    'Founding Settler's ticket' NFTs

*/

pragma solidity 0.8.1;

import "./Founding Settlers List.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SettlersTickets is ERC1155, FoundingSettlersList, Ownable {
    address public extrasHolder = address(this);
    
    uint public constant initialSupply = 100;
    uint public constant totalSupply = initialSupply;

    string public name;
    string public symbol;

    constructor() ERC1155("https://lmdrlhtrixymo3ezatsyjyntx5ahrmbnyknxslmue6oq4ywfw2sq.arweave.net/WwcVnnFF8MdsmQTlhOGzv0B4sC3Cm3ktlCedDmLFtqU") {
        
        require (addresses.length <= initialSupply, "address list is too large: # of addresses > initial supply");

        name = "Metanoia Founding Settlers Ticket";
        symbol = "METANOIA TICKET";
        
        _initList();
        uint _tokenID;

        // mint and send a unique-ID ticket to each address in the founding settlers list
        for (_tokenID = 1; _tokenID <= addresses.length; _tokenID++) {
            _mint(addresses.list[_tokenID], _tokenID, 1, "");
        }

        // mint and send extras to the extrasHolder address
        for (; _tokenID <= initialSupply; _tokenID++) {
            _mint(extrasHolder, _tokenID, 1, "");
        }
    }

    function sendTicket(address to, uint ticketID) public onlyOwner {
        _safeTransferFrom(extrasHolder, to, ticketID, 1, "");
    }
}