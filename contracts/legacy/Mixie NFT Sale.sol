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


    This is the contract responsible for the sale of the Founding Citizens NFT collection.

*/

pragma solidity 0.8.4;

import "../EmergencyPausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; 
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../utils/Interfaces.sol";
import "../utils/Constants.sol";

contract FoundingNFTSale is Initializable, ReentrancyGuard, EmergencyPausable {

    event stateUpdated(address indexed msgSender, Update indexed update);
    event ERC1155storageContractChanged(
        address indexed msgSender, 
        address indexed oldERC1155storageContract,
        address indexed newERC1155storageContract
    );
    event privilegedBuyersListContractChanged(
        address indexed msgSender, 
        address indexed oldPrivilegedBuyersListContract,
        address indexed newPrivilegedBuyersListContract
    );
    event usdcEscrowContractChanged(
        address indexed msgSender, 
        address indexed oldUsdcEscrowContract,
        address indexed newUsdcEscrowContract
    );
    event mintNextNftActionSent(
        address indexed msgSender, 
        address indexed mintedTo, 
        address indexed actionReceivingAddress
    );
    event preLoadURIsActionSent(address indexed msgSender, address indexed actionReceivingAddress);
    event startTimeChanged(address indexed msgSender, uint indexed oldStartTime, uint indexed newStartTime);
    event endTimeChanged(address indexed msgSender, uint indexed oldEndTime, uint indexed newEndTime);
    event nftsBought(address indexed msgSender, uint indexed amount, uint indexed totalPrice);

    IMintStorage public ERC1155storageContract;
    IPrivilegedListStorage public privilgedBuyersListContract;
    IUsdcStorage public usdcEscrowStorageContract;
    address public treasuryAddress = const_metanoia_treasuryAddress;

    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");
    bytes32 public constant POST_SALE_MINTER_ROLE = keccak256("POST_SALE_MINTER_ROLE");

    // NEEDS a mapping (uint => address) to store who the original minters were 
    
    bool initialized;

    uint startTime; //set to the year 2030 initially, needs to be updated once date is finalized 
	uint topTime;
    uint endTime;

    uint constant units = 10**6;
    uint topPrice;
    // uint topPrice;
    uint BottomPrice;

    uint constant priceDecreasePerMinute = (units * 25) / 8;

    struct Update {
        uint price;
        uint time;
        bool saleIsLive;
    }
    Update public lastUpdate;

    modifier requiresUpdate() {
        require(lastUpdate.time == block.timestamp, "timestamp is not up-to-date");
        _;
    }

    modifier pushesUpdate() {
        updateState();
        _;
    }

    modifier requiresConsistentState() {
        require(startTime <= endTime, "startTime is later than endTime");
        _;
    }

    function initialize() public override initializer {
        startTime   = 1893484800; //set to the year 2030 initially, needs to be updated once date is finalized 
        topTime	    = 1893484820;
        endTime     = 1993484900; //set to some date in the distant future, needs to be updated once date is finalized

        topPrice = 10 * units;
        // topPrice = 10000 * units;
        BottomPrice = 1000 * units;

        lastUpdate = Update(10000, block.timestamp, false);
        super.initialize();
    }

    function updateState() internal requiresConsistentState {
        //update price
        lastUpdate.price = topPrice - ((block.timestamp - topTime) / 60 * priceDecreasePerMinute);

        //update time
        lastUpdate.time = block.timestamp;
        
        //update saleIsLive
        if (block.timestamp >= startTime && block.timestamp <= endTime) {
            lastUpdate.saleIsLive = true;
        } else {
            lastUpdate.saleIsLive = false;
        }
        emit stateUpdated(_msgSender(), lastUpdate);
    }

    function setERC1155StorageContractAddress(address storageAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ERC1155storageContractChanged(_msgSender(), address(ERC1155storageContract), storageAddress);
        ERC1155storageContract = IMintStorage(storageAddress);
    }

    function setPrivilegedBuyersListContractAddress(address storageAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit privilegedBuyersListContractChanged(_msgSender(), address(privilgedBuyersListContract), storageAddress);
        privilgedBuyersListContract = IPrivilegedListStorage(storageAddress);
    }

    function setUsdcEscrowContractAddress(address storageAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit usdcEscrowContractChanged(_msgSender(), address(usdcEscrowStorageContract), storageAddress);
        usdcEscrowStorageContract = IUsdcStorage(storageAddress);
    }

    function mintNextNftToAddress(address to) internal whenNotPaused {
        IMintStorage(ERC1155storageContract).mintNextNftToAddress(to);
        emit mintNextNftActionSent(_msgSender(), to, address(ERC1155storageContract));
    }

    function preLoadURIs(uint[] memory ids, string[] memory uris) 
    public whenNotPaused {
        require(
            hasRole(URI_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not URI Manager or Admin"
        );
        IMintStorage(ERC1155storageContract).preLoadURIs(ids, uris);
        emit preLoadURIsActionSent(_msgSender(), address(ERC1155storageContract));
    }

    function getNextUnusedToken() public view returns(uint) {
        return IMintStorage(ERC1155storageContract).getNextUnusedToken();
    }

    function getMaxSupply() public view returns(uint) {
        return IMintStorage(ERC1155storageContract).getMaxSupply();
    }

    function setstartTime(uint unixTime) public {
        require(
            hasRole(SALE_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Sale Manager or Admin"
        );
        emit startTimeChanged(_msgSender(), startTime, unixTime);
        startTime = unixTime;
		topTime = unixTime;
    }

    // if wanting to manually end the sale, set endTime to current or recently passed unixTime
    function setEndTime(uint unixTime) public {
        require(
            hasRole(SALE_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Sale Manager or Admin"
        );
        emit endTimeChanged(_msgSender(), endTime, unixTime);
        endTime = unixTime;
    }

    function calculateDiscountedPrice(address prospectiveBuyer, uint discountRate) 
    public requiresUpdate view returns(uint) {
        require(privilgedBuyersListContract.addressHasCoupon(prospectiveBuyer, discountRate), string(abi.encodePacked(
            "Address ", prospectiveBuyer, " does not have a coupon with a discount rate of ", discountRate, "%")));
        uint price = lastUpdate.price / 100 * (100 - discountRate);
        return price;
    }

    function updateAndCalculateDiscountedPrice(address prospectiveBuyer, uint discountRate) 
    public pushesUpdate() returns(uint) {
        return calculateDiscountedPrice(prospectiveBuyer, discountRate);
    }

    function _buyNFTs(uint amount, uint totalPrice) internal whenNotPaused {
        usdcEscrowStorageContract.decreaseUsdcBalance(msg.sender, totalPrice);
        for (uint i = 0; i < amount; i++) {
			mintNextNftToAddress(msg.sender);
    	}
		topTime = lastUpdate.time;
        emit nftsBought(_msgSender(), amount, totalPrice);
	}

    function buyNFTs(uint amount) external pushesUpdate whenNotPaused nonReentrant { //requires using existing balance
        require(amount <= 10, "Can only puchase up to 10 Mixies at a time - for more, ask about bulk buying");
        uint price = lastUpdate.price;
        _buyNFTs(amount, price * amount);
    }

    function buyNftsWithDiscounts(uint amount, uint[] memory discountRate) 
    external pushesUpdate whenNotPaused nonReentrant {
        uint[] memory prices;
		uint totalPrice;
		for (uint i = 0; i < amount; i++) {
            // authorizes that the applied discounts are approved
            prices[i] = calculateDiscountedPrice(msg.sender, discountRate[i]); 
			totalPrice += prices[i];
            privilgedBuyersListContract.useCoupon(msg.sender, discountRate[i]);
        }
        _buyNFTs(amount, totalPrice);
    }

    function bulkBuyNfts(uint amount, uint totalPrice) external pushesUpdate whenNotPaused nonReentrant{
        require(
            privilgedBuyersListContract.addressHasCoupon(msg.sender, totalPrice),
            "You do not have a bulk buy coupon with those parameters"
        );
        privilgedBuyersListContract.useCoupon(msg.sender, totalPrice);
        _buyNFTs(amount, totalPrice);
    }

    function mintNextToTreasuryAddress() external pushesUpdate whenNotPaused nonReentrant{
        require(
            hasRole(POST_SALE_MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Post-Sale Minter or Admin"
        );
        require(
            block.timestamp > endTime && !lastUpdate.saleIsLive, 
            "Cannot mint to treasury address until sale is finished"
        );
        uint leftToMint = getMaxSupply() - (getNextUnusedToken()-1);
        require(leftToMint > 0, "No tokens left to mint");
        mintNextNftToAddress(treasuryAddress);
    }

    function mintNextManyToTreasuryAddress(uint numberToMint) external pushesUpdate whenNotPaused nonReentrant {
        require(
            hasRole(POST_SALE_MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Post-Sale Minter or Admin"
        );
        require(
            block.timestamp > endTime && !lastUpdate.saleIsLive, 
            "Cannot mint to treasury address until sale is finished"
        );
        uint leftToMint = getMaxSupply() - (getNextUnusedToken()-1);
        leftToMint = Math.min(leftToMint, numberToMint);
        for (; leftToMint > 0; leftToMint--) {
            mintNextNftToAddress(treasuryAddress);
        }
        mintNextNftToAddress(treasuryAddress);
    }
}