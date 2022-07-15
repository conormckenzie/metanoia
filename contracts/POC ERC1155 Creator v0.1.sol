//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// WARNING: Access control has been disabled for this proof of concept.

import "./ERC1155MultiUri.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POCTestNfts is ERC1155MultiUri {
    address public extrasHolder = address(this);
    
    uint public constant initialSupply = 0;
    uint public constant totalSupply = initialSupply;
    uint public nextTokenID = 1;

    string public name;
    string public symbol;
    mapping(uint => string) uriList;
    mapping(uint => uint) nftTypes;

    function getNftType(uint nftId) external view returns (uint) {
        return nftTypes[nftId];
    }
    
    constructor() ERC1155("https://bafybeib4g7hewm2qwjgoatikznli3rrjnutet5t34lajsbb54gw4z7vh7u.ipfs.infura-ipfs.io/foundingSettlersTicket.json") {

        name = "Metanoia NFT";
        symbol = "METANOIA-NFT";

        // 1: single-use
        // 2: MFU
        // 3: infinite-use
        uriList[1] = "https://lyetm5dfqffmxvdaddrd5c3saczy33knndq3zs5oof437o3bwa.arweave.net/Xgk2dGWBSsvU_YBjiPotyALON7U1o4bzLrnF5v7thsM";
        uriList[2] = "https://3s3gyhwh4m4bmklbr5qt6xtem6oqnrmyaotwnymefzc6bgiaqksq.arweave.net/3LZsHsfjOBYpYY9hP15kZ50GxZgDp2bhhC5F4JkAgqU";
        uriList[3] = "https://utyoidgqfdvmfjgqmlhq4id26bg4scm5dsygaqw732jyjduwiy.arweave.net/pPDkD_NAo6sKk0GLPDiB68E3JCZ0csGBC396ThI6WRk";
    }

    function mintNewTicketCollection(address to, uint amount, uint nftType) public /*onlyOwner*/ {
        nextTokenID++;
        require(nftType >= 1 && nftType <= 3, "NFT type must be between 1 and 3");
        nftTypes[nextTokenID-1] = nftType;
        _mintWithURI(to, nextTokenID-1, amount, "", uriList[nftType]);
    }

    function sendTicket(address to, uint ticketID) public /*onlyOwner*/ {
        _safeTransferFrom(extrasHolder, to, ticketID, 1, "");
    }

    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
    //     return
    //         interfaceId == type(IERC1155).interfaceId ||
    //         interfaceId == type(IERC1155MetadataURI).interfaceId ||
    //         interfaceId == type(IERC1155Receiver).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }
}