// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Metanoia Settlers Airdrop Raffle.sol";

contract $SettlersAirDropRaffle is SettlersAirDropRaffle {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_rand_Returned(uint256 arg0);

    constructor() {}

    function $_pseudoRandomNumbers(uint256 arg0) external view returns (uint256) {
        return _pseudoRandomNumbers[arg0];
    }

    function $_randomsAreFresh() external view returns (bool) {
        return _randomsAreFresh;
    }

    function $_internalSeed() external view returns (uint256) {
        return _internalSeed;
    }

    function $_getDistinctPseudoRandomNumbers(uint256 _seed,uint256 _quantity,uint256 _max) external {
        return _getDistinctPseudoRandomNumbers(_seed,_quantity,_max);
    }

    function $_rand(uint256 _seed,uint256 _i) external returns (uint256) {
        (uint256 ret0) = super._rand(_seed,_i);
        emit $_rand_Returned(ret0);
        return (ret0);
    }

    function $_resetRandomNumbers(uint256 _quantity) external {
        return _resetRandomNumbers(_quantity);
    }

    function $_mintByAirdrop(
    uint256 tokenID,
    uint256 amountPerRecipient,
    string calldata newuri) external {
        return _mintByAirdrop(tokenID,amountPerRecipient,newuri);
    }

    function $_mintByRaffle(uint256 tokenID,uint256 amountPerWinner,uint256 numberOfWinners,uint256 randomSeed,string calldata newuri) external {
        return _mintByRaffle(tokenID,amountPerWinner,numberOfWinners,randomSeed,newuri);
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_requireNotPaused() external view {
        return super._requireNotPaused();
    }

    function $_requirePaused() external view {
        return super._requirePaused();
    }

    function $_pause() external {
        return super._pause();
    }

    function $_unpause() external {
        return super._unpause();
    }

    function $_checkRole(bytes32 role) external view {
        return super._checkRole(role);
    }

    function $_checkRole(bytes32 role,address account) external view {
        return super._checkRole(role,account);
    }

    function $_setupRole(bytes32 role,address account) external {
        return super._setupRole(role,account);
    }

    function $_setRoleAdmin(bytes32 role,bytes32 adminRole) external {
        return super._setRoleAdmin(role,adminRole);
    }

    function $_grantRole(bytes32 role,address account) external {
        return super._grantRole(role,account);
    }

    function $_revokeRole(bytes32 role,address account) external {
        return super._revokeRole(role,account);
    }

    function $_setURI(uint256 id,string calldata newuri) external {
        return super._setURI(id,newuri);
    }

    function $_mintWithURI(address to,uint256 id,uint256 amount,bytes calldata data,string calldata newuri) external {
        return super._mintWithURI(to,id,amount,data,newuri);
    }

    function $_mintWithoutURI(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mintWithoutURI(to,id,amount,data);
    }

    function $_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function $_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function $_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function $_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function $_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function $_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function $_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_afterTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
    
    function checkIfItExists(_tokenID) external view returns (bool) {
        if(exists(_tokenID){
        return true;
        } 
        else {
        return false
        }

    }

    receive() external payable {}
}
