//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Founding Settlers list.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SettlersTickets is ERC1155, FoundingSettlersList {
    address public contractGovernor;
    address public extrasHolder = address(this);
    
    uint public constant initialSupply = 100;
    uint public constant totalSupply = initialSupply;

    string public name;
    string public symbol;

    modifier onlyGovernor() {
        require(msg.sender == contractGovernor, 
            "Permission denied. Only the contract governor can perform that action.");
            _;
    }

    constructor() ERC1155("https://bafybeib4g7hewm2qwjgoatikznli3rrjnutet5t34lajsbb54gw4z7vh7u.ipfs.infura-ipfs.io/foundingSettlersTicket.json") {
        
        require (addresses.length <= initialSupply, "address list is too large: # of addresses > initial supply");

        name = "Metanoia Founding Settlers Ticket";
        symbol = "MFS TICKET";
        
        contractGovernor = msg.sender;
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

    function sendTicket(address _to, uint _ticketID) public onlyGovernor {
        _safeTransferFrom(extrasHolder, _to, _ticketID, 1, "");
    }
}