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



pragma solidity 0.8.4;

contract MixieNftSaleIntegratedContractTest8 is 
ERC1155Supply, ERC2981ContractWideRoyalties, ReentrancyGuard, EmergencyPausable {

    // IN PRODUCTION, ALL TESTING TOGGLES SHOULD BE FALSE
    bool constant testing1 = true; // starting price is $10000 (false) or $0.10 (true) USD, ending price is 1/10th
    bool constant testing2 = true; // unused

    /// ERROR MESSAGES:
    // ERR1: "Sender is not Minter or Admin"
    // ERR1A:"Sender is not Minter or Admin or recipient"
    // ERR2: "timestamp is not up-to-date"
    // ERR3: "startTime is later than endTime"
    // ERR4: "Sender is not Sale Manager or Admin"
    // ERR5: "Given address does not have a coupon with the given discount rate
    // ERR6: "Can only puchase up to 10 Mixies at a time - for more, ask about bulk buying"
    // ERR7: "You do not have a bulk buy coupon with those parameters"
    // ERR8: "Sender is not Post-Sale Minter or Admin"
    // ERR9: {next candidate in mintNextToTreasuryAddress()}

    ///GENERAL-----------------------------
    
    event contractUriChanged(address indexed msgSender, string indexed olduri, string indexed newuri);
    event royaltyInfoChanged(address indexed msgSender, address indexed recipient, uint indexed value);
    event stateUpdated(address indexed msgSender, Update indexed update);

    event startTimeChanged(address indexed msgSender, uint indexed oldStartTime, uint indexed newStartTime);
    event endTimeChanged(address indexed msgSender, uint indexed oldEndTime, uint indexed newEndTime);
    event nftsBought(address indexed msgSender, uint indexed amount, uint indexed totalPrice);
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
    event erc20Refunded(address indexed msgSender, address indexed to, address indexed tokenAddress, uint amount);
    event addedAddress(address indexed msgSender, address indexed addedAddress);
    event removedAddress(address indexed msgSender, address indexed removedAddress);
    event couponAdded(
        address indexed msgSender, 
        address indexed couponRecipient, 
        uint indexed couponType, 
        uint discountRate, 
        uint numberOfMixies, 
        uint totalPrice, 
        uint numberOfUses
    );
    event couponRemoved(
        address indexed msgSender, 
        address indexed couponHolder, 
        uint couponType, 
        uint discountRate, 
        uint numberOfMixies, 
        uint totalPrice, 
        uint numberOfUses,
        uint indexed id
    );
    event couponUsed(
        address indexed msgSender, 
        address indexed couponHolder, 
        uint couponType, 
        uint discountRate, 
        uint numberOfMixies, 
        uint totalPrice, 
        uint numberOfUses,
        uint indexed id
    );

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");
    bytes32 public constant POST_SALE_MINTER_ROLE = keccak256("POST_SALE_MINTER_ROLE");

    bytes32 public constant USDC_MANAGER_ROLE = keccak256("USDC_MANAGER_ROLE");
    bytes32 public constant ADDRESS_MANAGER_ROLE = keccak256("ADDRESS_MANAGER_ROLE");
    bytes32 public constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER_ROLE");
    bytes32 public constant COUPON_USER_ROLE = keccak256("COUPON_USER_ROLE");


    /// @notice This address will receive the royalty payments from any sales of the NFTs this contract creates.
    address public royaltyRecipient = 0x3d2835cAB8b2Aa7FE825d27D0b6d6E9B6777cC3d;

    /// @notice This specifies the royalty fee in basis points (bp): 100 bp = 1%
    uint royaltyFee = 500;

    /// @dev    This URI is used to store the royalty and collection information on OpenSea.
    // solhint-disable-next-line max-line-length
    string _contractUri = "";

     /// @dev    Some external applications use these variables to show info about the contract or NFT collection.
    string public constant name = "Metanoia Mixie (Egg)";
    string public symbol = "METANOIA MIXIE";

    function initialize() public override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x012d1deD4D8433e8e137747aB6C0B64864A4fF78);

        startTime   = block.timestamp;
        topTime	    = startTime;
        endTime     = 1993484900; //set to some date in the distant future, can be set to custom time by admin

        lastUpdate = Update(10000*units, block.timestamp, false);

        usdcTokenAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        usdcToken = IERC20(usdcTokenAddress);

        _setupList();
        _setRoyalties(royaltyRecipient, royaltyFee);
        

        super.initialize();
    }

    /// MINTING----------------------------

    uint public nextUnusedToken = 1;
    uint public maxSupply = 10000;

    constructor() ERC1155("") {
        initialize();
    }

    /** @notice Returns the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     */
    /// @dev    This method is separate from ERC2981 and does not use the on-chain variables that RoyaltyInfo uses.
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /** @dev    Sets the contract URI for the collection of tickets. This is used by OpenSea to 
     *          get information about the collection, including royalty information.
     *          This method does NOT update the on-chain variables that ERC2981 uses. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called to change the OpenSea royalties, `setRoyaltyInfo(address, uint)` should also be called.
     */
    /// @param  newUri The new contract URI.
    function setContractUri(string calldata newUri) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        emit contractUriChanged(_msgSender(), _contractUri, newUri);
        _contractUri = newUri;
    }

    /** @dev    Sets the ERC2981 royalty info for the collection of tickets. 
     *          This method does NOT update the contractURI royalty values which are used by OpenSea. 
     *          To maintain consistency between the OpenSea royalties and ERC2981 royalties, when this function is 
     *          called, `setContrctUri(string)` should also be called to point to a new metadata file which contains
     *          the updated royalty information.
     */
    /// @param  recipient The address which will receive royalty payments
    /// @param  feeInBasisPoints The royalty fee in basis points (units of 0.01%)
    function setRoyaltyInfo(address recipient, uint feeInBasisPoints) 
    public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        royaltyRecipient = recipient;
        royaltyFee = feeInBasisPoints;
        _setRoyalties(royaltyRecipient, royaltyFee);
        emit royaltyInfoChanged(_msgSender(), recipient, feeInBasisPoints);
    }

    function _mintNextNftToAddress(address to) internal whenNotPaused {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == to,
            "ERR1A"
            //"Sender is not Minter or Admin or recipient"
        );
        nextUnusedToken++;
        _mint(to, nextUnusedToken-1, 1, "");
    }
    function mintNextNftToAddress(address to) external whenNotPaused nonReentrant {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR1"
            //"Sender is not Minter or Admin"
        );
        _mintNextNftToAddress(to);
    }

    /// SALE----------------------------------
    uint startTime;
	uint public topTime;
    uint endTime;
    // uint constant blockTime = 2150; // an estimate of the average time between blocks on polygon mainnet in ms

    //uint constant units = 10**6;
    uint constant units = testing1 ? 10**0 : 10**6; 
    function getUnits() external pure returns(uint) { return units; }
    uint constant topPrice = 10000 * units;
    uint constant bottomPrice = 1000 * units;

    uint constant daysBetweenTopAndBottomPrice = 2;
    // preferred to use priceDecreasePerDay since it has the highest precision
    uint constant priceDecreasePerDay = (topPrice - bottomPrice) / daysBetweenTopAndBottomPrice;
    uint constant priceDecreasePerHour = priceDecreasePerDay / 24;
    uint constant priceDecreasePerMinute = priceDecreasePerDay / (24*60); 
    uint constant priceDecreasePerSecond = priceDecreasePerDay / (24*60*60);

    struct Update {
        uint price;
        uint time;
        bool saleIsLive;
    }
    Update public lastUpdate;

    address public treasuryAddress;

    modifier requiresUpdate() {
        require(
            lastUpdate.time == block.timestamp, 
            "ERR2"
            //"timestamp is not up-to-date"
        );
        _;
    }

    modifier pushesUpdate() {
        updateState();
        _;
    }

    modifier requiresConsistentState() {
        require(
            startTime <= endTime, 
            "ERR3"
            //"startTime is later than endTime"
        );
        _;
    }

    function getUpdatedPrice() public view returns(uint) {
        //update price
        // 1) difference between current time and topTime (units: seconds)
        // 2) difference between

        // rearrangement of the following formula:
        // price = topPrice - (block.timestamp - topTime) * priceDecreasePerSecond
        int tempPrice;
        // using perHour instead of perSecond works for low and high values of units due to higher precision
        tempPrice = int(topPrice - (((block.timestamp - topTime) * priceDecreasePerHour) / (60*60)));
        if (tempPrice < int(bottomPrice) || tempPrice < 0 /*Not strictly necessary, but good defensive programming*/) {
            return bottomPrice;
        }
        else {
            return uint(tempPrice);
        }
    }

    function updateState() public requiresConsistentState {
        
        lastUpdate.price = getUpdatedPrice();

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
    // function updateState() external nonReentrant {

    // }

    function setstartTime(uint blockNumber) public {
        require(
            hasRole(SALE_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR4"
            //"Sender is not Sale Manager or Admin"
        );
        emit startTimeChanged(_msgSender(), startTime, blockNumber);
        startTime = blockNumber;
		topTime = blockNumber;
    }

    // if wanting to manually end the sale, set endTime to current or recently passed blockNumber 
    // and then update the state using updateState()
    function setEndTime(uint blockNumber) public {
        require(
            hasRole(SALE_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR4"
            //"Sender is not Sale Manager or Admin"
        );
        emit endTimeChanged(_msgSender(), endTime, blockNumber);
        endTime = blockNumber;
    }

    function blockTimestamp() external view returns(uint) {
        return block.timestamp;
    }

    function calculateDiscountedPrice(address prospectiveBuyer, uint discountRate) 
    internal view returns(uint) {
        require(
            addressHasType1Coupon(prospectiveBuyer, discountRate), 
            "ERR5"
            /*
            string(abi.encodePacked(
            "Address ", prospectiveBuyer, " does not have a coupon with a discount rate of ", discountRate, "%"))
            */
        );
        uint price = (getUpdatedPrice() * (100 - discountRate)) / 100;
        return price;
    }

    function updateAndCalculateDiscountedPrice(address prospectiveBuyer, uint discountRate) 
    external nonReentrant pushesUpdate returns(uint) {
        return calculateDiscountedPrice(prospectiveBuyer, discountRate);
    }

    function _buyNFTs(uint amount, uint totalPrice) internal requiresUpdate whenNotPaused {
        require(lastUpdate.saleIsLive);
        _decreaseUsdcBalance(msg.sender, totalPrice);
        for (uint i = 0; i < amount; i++) {
			_mintNextNftToAddress(msg.sender);
    	}
		topTime = lastUpdate.time;
        emit nftsBought(_msgSender(), amount, totalPrice);
	}

    function buyNFTs(uint amount) external pushesUpdate whenNotPaused nonReentrant { //requires using existing balance
        require(
            amount <= 10, 
            "ERR6"
            // "Can only puchase up to 10 Mixies at a time - for more, ask about bulk buying"
        );
        uint price = lastUpdate.price;
        _buyNFTs(amount, price * amount);
    }

    function buyNftWithDiscounts(uint discountRate) 
    external pushesUpdate whenNotPaused nonReentrant {
        uint price;
		uint totalPrice;
            // authorizes that the applied discount is approved
            price = calculateDiscountedPrice(msg.sender, discountRate); 
			totalPrice += price;
            useType1Coupon(msg.sender, discountRate);
        _buyNFTs(1, totalPrice);
    }

    function bulkBuyNfts(uint amount, uint numberOfMixies, uint totalPrice) 
    external pushesUpdate whenNotPaused nonReentrant{
        require(
            addressHasType2Coupon(msg.sender, numberOfMixies, totalPrice),
            "ERR7"
            // "You do not have a bulk buy coupon with those parameters"
        );
        useType2Coupon(msg.sender, numberOfMixies, totalPrice);
        _buyNFTs(amount, totalPrice);
    }

    function mintNextToTreasuryAddress() external pushesUpdate whenNotPaused nonReentrant{
        require(
            hasRole(POST_SALE_MINTER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERR8"
            // "Sender is not Post-Sale Minter or Admin"
        );
        require(
            block.timestamp > endTime && !lastUpdate.saleIsLive, 
            "Cannot mint to treasury address until sale is finished"
        );
        uint leftToMint = maxSupply - (nextUnusedToken-1);
        require(leftToMint > 0, "No tokens left to mint");
        _mintNextNftToAddress(treasuryAddress);
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
        uint leftToMint = maxSupply - (nextUnusedToken-1);
        leftToMint = Math.min(leftToMint, numberToMint);
        for (; leftToMint > 0; leftToMint--) {
            _mintNextNftToAddress(treasuryAddress);
        }
        _mintNextNftToAddress(treasuryAddress);
    }

    /// ESCROW----------------------------------

    address usdcTokenAddress; 
    IERC20 usdcToken;
    mapping (address => uint) public usdcBalances;

    function receiveUSDC(uint amount) external whenNotPaused nonReentrant {
        require(amount > 0, "amount transferred must be a positive value");
        //requires javascript code to get buyer to first approve the allowance
        usdcToken.transferFrom(msg.sender, address(this), amount);
        usdcBalances[msg.sender] += amount;
        emit usdcReceived(_msgSender(), amount);
    }

    function refundUsdcTo(address to, uint amount) external whenNotPaused nonReentrant {
        _decreaseUsdcBalance(_msgSender(), amount);
        usdcToken.transfer(to, amount);
        emit usdcRefunded(_msgSender(), to, amount);
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
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not USDC Manager, Admin, or the address which would have its USDC balance decreased"
        );
        require(amount > 0, "must update the USDC balance with a (positive or negative) non-zero amount");
        require(amount <= usdcBalances[address_], string(abi.encodePacked(
            "cannot decrease USDC balance of ", address_, 
            " by more than the existing balance ", usdcBalances[address_])));
        usdcBalances[address_] -= amount;
        emit usdcBalanceDecreased(_msgSender(), address_, amount);
    }
    function decreaseUsdcBalance(address address_, uint amount) external nonReentrant {
        require(
            hasRole(USDC_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not USDC Manager or Admin"
        );
        _decreaseUsdcBalance(address_, amount);
    }

    function refundNonUsdcErc20(address to, address tokenAddress, uint amount) public {
        require(
            hasRole(USDC_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not USDC Manager or Admin"
        );
        IERC20(tokenAddress).transfer(to, amount);
        emit erc20Refunded(_msgSender(), to, tokenAddress, amount);
    } 
    
    receive() external payable {
        revert("This contract only accepts USDC");
    }

    // fallback() external payable {
    //     revert("Fallback triggered - please interact with this contract only via it's available functions");
    // }

    /// COUPONS

    struct Coupon {
        // coupon types - 1: regular discount, 2: bulk buy
        uint couponType;
        uint numberOfUses; // applies to coupon types 1, 2

        uint discountRate; // applies to coupon type 1
        
        uint numberOfMixies; // applies to coupon type 2
        uint totalPrice; // applies to coupon type 2
    }

    // struct idList {
    //     uint ids;
    // }

    struct CouponList { // each address in addressList has one couponList
    // WARNING: must be iterated over to show the user's existing coupons
        uint length;
        mapping(uint/*id*/ => Coupon) coupons; 
    }

    struct CouponListList {
        uint length;
        mapping(uint/*id*/ => address) addresses; // <addresses> is enumerable, 1-indexed
        mapping(address => uint/*id*/) ids; 
        mapping(uint/*id*/ => CouponList) couponLists;
        // <ids> tracks the same info as <addresses>, but is inverted (allows address to be used as a key)
    }
    CouponListList public couponListList;

    function idOf(address address_) public view returns(uint) {
        return couponListList.ids[address_];
    }

    function couponListLength(address address_) public view returns(uint) {
        return couponListList.couponLists[idOf(address_)].length;
    }

    function viewCoupon(address address_, uint couponId) external view returns(
        uint couponType, 
        uint numberOfUses,
        uint discountRate,        
        uint numberOfMixies,
        uint totalPrice
    ) {
        return (
            couponListList.couponLists[idOf(address_)].coupons[couponId].couponType,
            couponListList.couponLists[idOf(address_)].coupons[couponId].numberOfUses,
            couponListList.couponLists[idOf(address_)].coupons[couponId].discountRate,
            couponListList.couponLists[idOf(address_)].coupons[couponId].numberOfMixies,
            couponListList.couponLists[idOf(address_)].coupons[couponId].totalPrice
        );
    }

    function addressExists(address address_) public view returns(bool) {
        return (idOf(address_) != 0);
    }

    function addressHasCoupon(address address_) public view returns(bool) {
        return (couponListList.couponLists[idOf(address_)].length != 0);
    }

    function addressHasType1Coupon(address address_, uint discountRate/*, uint mode*/) public view returns(bool) {
        // solhint-disable-next-line max-line-length
        // require(mode >= 1 && mode <= 2, "Mixie NFT Sale Privileged Boyers List: addressHasType1Coupon: invalid mode");
        // if (mode == 1) { // discount rate provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 1 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate
                ) {
                    return true;
                }
            }
            return false;
        // }
        // if (mode == 2) { // discount rate not provided   
        //     for (uint i = 0; i < couponListLength(address_); i++) {
        //         if (
        //             couponListList.couponLists[idOf(address_)].coupons[i].couponType == 1
        //         ) {
        //             return true;
        //         }
        //     }
        //     return false;
        // }
        // revert("Mixie NFT Sale Privileged Boyers List: addressHasType1Coupon: invalid mode");
    }

    function addressHasType2Coupon(address address_, uint numberOfMixies, uint totalPrice/*, uint mode*/) 
    public view returns(bool) {
        // solhint-disable-next-line max-line-length
        // require(mode >= 1 && mode <= 4, "Mixie NFT Sale Privileged Boyers List: addressHasType2Coupon: invalid mode");
        // if (mode == 1) { // both numberOfMixies and totalPrice are provided
            for (uint i = 0; i < couponListLength(address_); i++) {
                if (
                    couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
                    couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies &&
                    couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
                ) {
                    return true;
                }
            }
            return false;
        // }
        // if (mode == 2) { // only numberOfMixies is provided
        //     for (uint i = 0; i < couponListLength(address_); i++) {
        //         if (
        //             couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
        //             couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies
        //         ) {
        //             return true;
        //         }
        //     }
        //     return false;
        // }
        // if (mode == 3) { // only totalPrice is provided
        //     for (uint i = 0; i < couponListLength(address_); i++) {
        //         if (
        //             couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2 &&
        //             couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
        //         ) {
        //             return true;
        //         }
        //     }
        //     return false;
        // }
        // if (mode == 4) { // neither numberOfMixies nor totalPrice is provided
        //     for (uint i = 0; i < couponListLength(address_); i++) {
        //         if (
        //             couponListList.couponLists[idOf(address_)].coupons[i].couponType == 2
        //         ) {
        //             return true;
        //         }
        //     }
        //     return false;
        // }
        // revert("Mixie NFT Sale Privileged Boyers List: addressHasType2Coupon: invalid mode");
    }

    function _addAddress(address address_) internal whenNotPaused {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Approved Role: Address Manager, Coupon Manager, Coupon User, or Admin"
        );
        couponListList.length++;
        couponListList.addresses[couponListList.length] = address_; //<addressList.addresses> is 1-indexed not 0-indexed
        couponListList.ids[address_] = couponListList.length;
        emit addedAddress(_msgSender(), address_);
    }
    function addAddress(address address_) external nonReentrant {
        _addAddress(address_);
    }

    /*
    *  @dev Removes <address_> from <addressList> and moves the last address in
    *       <addressList.addresses> into its spot. 
    *       Updates <addressList.ids> accordingly.  
    */
    function _removeAddress(address address_) internal whenNotPaused {
        require(
            hasRole(ADDRESS_MANAGER_ROLE, _msgSender()) || 
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Address Manager or Admin"
        );
        
        uint _toRemove1 = idOf(address_);
        address _toRemove2 = address_;

        uint _toMove1 = couponListList.length;
        address _toMove2 = couponListList.addresses[couponListList.length];

        couponListList.addresses[_toRemove1] = couponListList.addresses[_toMove1];
        delete couponListList.addresses[_toMove1];

        couponListList.ids[_toRemove2] = couponListList.ids[_toMove2];
        delete couponListList.ids[_toMove2];
        
        couponListList.length--;
        emit removedAddress(_msgSender(), address_);
    }
    function removeAddress(address address_) external nonReentrant {
        _removeAddress(address_);
    }

    function _addCoupon(
        address address_, 
        uint couponType, 
        uint discountRate,
        uint numberOfMixies, 
        uint totalPrice,
        uint numberOfUses
    ) internal whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender is not Coupon Manager or Admin"
        );
        if (!addressExists(address_)) {
            _addAddress(address_);
        }
        //currentCouponList = addressList.couponLists[idOf(address_)]
        couponListList.couponLists[idOf(address_)].length++;
        //currentCoupon = addressList.couponLists[idOf(address_)].coupons[currentCouponList.length]
        couponListList.couponLists[idOf(address_)]
            .coupons[couponListLength(address_)]
                .discountRate = discountRate;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .numberOfUses = numberOfUses;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .couponType = couponType;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .numberOfMixies = numberOfMixies;
        couponListList.couponLists[idOf(address_)].
            coupons[couponListLength(address_)]
                .totalPrice = totalPrice;
        emit couponAdded(_msgSender() ,address_, couponType, discountRate, numberOfMixies, totalPrice, numberOfUses);
    }
    function addCoupon(
        address address_, 
        uint couponType, 
        uint discountRate,
        uint numberOfMixies, 
        uint totalPrice,
        uint numberOfUses
    ) external nonReentrant {
        _addCoupon(
            address_,
            couponType,
            discountRate,
            numberOfMixies,
            totalPrice,
            numberOfUses
        );
    }

    function _removeCoupon(address address_, uint id) internal whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        
        emit couponRemoved(
            _msgSender() ,
            address_, 
            couponListList.couponLists[idOf(address_)].coupons[id].couponType, 
            couponListList.couponLists[idOf(address_)].coupons[id].discountRate, 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfMixies, 
            couponListList.couponLists[idOf(address_)].coupons[id].totalPrice, 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses,
            id
        );
        couponListList.couponLists[idOf(address_)].coupons[id] = 
            couponListList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        delete couponListList.couponLists[idOf(address_)].coupons[couponListLength(address_)];
        couponListList.couponLists[idOf(address_)].length--;
    }
    function removeCoupon(address address_, uint id) external nonReentrant {
        _removeCoupon(address_, id);
    }

    function _reduceCouponUses(address address_, uint id, uint numberOfUses) internal whenNotPaused {
        bool condition = (couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses >= numberOfUses);
        string memory errorMsg = string(abi.encodePacked(
            "Cannot reduce coupon uses by more than the number of uses for this coupon: ", 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses));
        require(condition, errorMsg);
        couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses -= numberOfUses;
        emit couponUsed(
            _msgSender() ,
            address_, 
            couponListList.couponLists[idOf(address_)].coupons[id].couponType, 
            couponListList.couponLists[idOf(address_)].coupons[id].discountRate, 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfMixies, 
            couponListList.couponLists[idOf(address_)].coupons[id].totalPrice, 
            couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses,
            id
        );
        if (couponListList.couponLists[idOf(address_)].coupons[id].numberOfUses <= 0) {
            _removeCoupon(address_, id);
        }
    }
    function reduceCouponUsesById(address address_, uint id, uint numberOfUses) external {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        _reduceCouponUses(address_, id, numberOfUses);
    } 

    function reduceType1CouponUses(address address_, uint discountRate, uint numberOfUses) internal whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        bool found = false;
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (couponListList.couponLists[idOf(address_)].coupons[i].discountRate == discountRate) 
            {
                _reduceCouponUses(address_, i, numberOfUses);
                found = true;
                break;
            }
        }
        require(found, "Matching coupon not found");
    }

    function reduceType2CouponUses(
        address address_, 
        uint numberOfMixies, 
        uint totalPrice, 
        uint numberOfUses) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        bool found = false;
        for (uint i = 0; i < couponListLength(address_); i++) {
            if (
                couponListList.couponLists[idOf(address_)].coupons[i].numberOfMixies == numberOfMixies &&
                couponListList.couponLists[idOf(address_)].coupons[i].totalPrice == totalPrice
            ) {
                _reduceCouponUses(address_, i, numberOfUses);
                found = true;
                break;
            }
        }
        require(found, "Matching coupon not found");
    }

    function useType1Coupon(address address_, uint discountRate) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        reduceType1CouponUses(address_, discountRate, 1);
    }

    function useType2Coupon(address address_, uint numberOfMixies, uint totalPrice) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        reduceType2CouponUses(address_, numberOfMixies, totalPrice, 1);
    }

    function useCoupon(
        address address_, 
        uint couponType, 
        uint discountRate,
        uint numberOfMixies, 
        uint totalPrice
    ) public whenNotPaused {
        require(
            hasRole(COUPON_MANAGER_ROLE, _msgSender()) ||
            hasRole(COUPON_USER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
            _msgSender() == address_,
            "Sender is not Coupon Manager, Coupon User, Admin, or Coupon Owner"
        );
        if (couponType == 1) {
            reduceType1CouponUses(address_, discountRate, 1);
            return;
        }
        else if (couponType == 2) {
            reduceType2CouponUses(address_, numberOfMixies, totalPrice, 1);
            return;
        }
        revert("Mixie NFT Sale Privileged Boyers List: useCoupon: invalid couponType");
    }

    function _setupList() internal {
        couponListList.length = 0;
        // _addAddress(0xc0ffee254729296a45a3885639AC7E10F9d54979);
        // _addAddress(0x59eeD72447F2B0418b0fe44C0FCdf15AAFfa1f77);
        // _addAddress(0xCb172d8fA7b46b53A6b0BDACbC5521b315D1d3F7);
        // _addAddress(0x5061b6b8B572776Cff3fC2AdA4871523A8aCA1E4);
        // _addAddress(0xff2710dF4D906414C01726f049bEb5063929DaA8);
        // _addAddress(0xb3c8801aF1E17a4D596E7678C1548094C872AE0D);
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