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


    This is the contract responsible for escrow of USDC.
*/


import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./EmergencyPausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity 0.8.4;

contract UsdcEscrowStorage is Initializable, ReentrancyGuard, EmergencyPausable {

    event usdcReceived(address indexed msgSender, uint indexed amount);
    event usdcRefunded(address indexed msgSender, address indexed usdcRecipient, uint indexed amount);
    event usdcTransferred(
        address indexed msgSender, 
        address indexed usdcSender, 
        address indexed usdcRecipient, 
        uint amount
    );
    event usdcBalanceIncreased(address indexed msgSender, address indexed affectedAddress, uint indexed amount);
    event usdcBalanceDecreased(address indexed msgSender, address indexed affectedAddress, uint indexed amount);
    
    bytes32 public constant USDC_MANAGER_ROLE = keccak256("USDC_MANAGER_ROLE");

    address usdcTokenAddress; 
    IERC20 usdcToken;
    mapping (address => uint) public usdcBalances;

    function initialize() public override initializer {
        usdcTokenAddress = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62;
        usdcToken = IERC20(usdcTokenAddress);
        super.initialize();
    }

    //IMPORTANT: Test that this catches all transfers to this address.
    //Probably doesn't :/
    function receiveUSDC(uint amount) external whenNotPaused nonReentrant {
        require(amount > 0, "amount transferred must be a positive value");
        //requires javascript code to get buyer to first approve the allowance
        usdcToken.transferFrom(msg.sender, address(this), amount);
        usdcBalances[msg.sender] += amount;
        emit usdcReceived(_msgSender(), amount);
    }

    //IMPORTANT: Check that this refunds the USDC correctly
    function refundUsdcTo(address to, uint amount) external whenNotPaused nonReentrant {
        _decreaseUsdcBalance(to, amount);
        usdcToken.transferFrom(address(this), to, amount);
        emit usdcRefunded(_msgSender(), to, amount);
    }

    function getUsdcBalance(address address_) external view returns(uint) {
        return usdcBalances[address_];
    }

    function transferUsdcBalance(address from, address to, uint amount) external whenNotPaused nonReentrant {
        require(
            hasRole(USDC_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not USDC Manager or Admin"
        );
        _decreaseUsdcBalance(from, amount);
        _increaseUsdcBalance(to, amount);
        emit usdcTransferred(_msgSender(), to, from, amount);
    }

    function _increaseUsdcBalance(address address_, uint amount) internal whenNotPaused {
        require(
            hasRole(USDC_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not USDC Manager or Admin"
        );
        require(amount > 0, "must update the USDC balance with a (positive or negative) non-zero amount");
        usdcBalances[address_] += amount;
        emit usdcBalanceIncreased(_msgSender(), address_, amount);
    }
    function increaseUsdcBalance(address address_, uint amount) external nonReentrant {
        _increaseUsdcBalance(address_, amount);
    }

    function _decreaseUsdcBalance(address address_, uint amount) internal whenNotPaused {
        require(
            hasRole(USDC_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not USDC Manager or Admin"
        );
        require(amount > 0, "must update the USDC balance with a (positive or negative) non-zero amount");
        require(amount <= usdcBalances[address_], string(abi.encodePacked(
            "cannot decrease USDC balance of ", address_, 
            " by more than the existing balance ", usdcBalances[address_])));
        usdcBalances[address_] -= amount;
        emit usdcBalanceDecreased(_msgSender(), address_, amount);
    }
    function decreaseUsdcBalance(address address_, uint amount) external nonReentrant {
        _decreaseUsdcBalance(address_, amount);
    }
    
    receive() external payable {
        revert("This contract only accepts USDC");
    }

    fallback() external payable {
        revert("Fallback triggered - please interact with this contract only via it's available functions");
    }

}