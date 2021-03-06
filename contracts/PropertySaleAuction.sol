pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/Whitelist.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./RealEstateRegistry.sol";

contract PropertySaleAuction is  Whitelist, Pausable, Destructible{
    
    address private  beneficiaryAddress;
    bytes32 private propertyId;
    uint256 private startingDate;
    uint256 private endingDate;
    uint256 private bidTime;
    
    uint256 private startingBid;
    bool private autoCloseable;
    uint256 private takeProfit;
    uint256 private autoCloseBid;
    uint256 public topBid;
    address public topBidder;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) private returnsPending;
    // Will be set true once the auction is complete, preventing any further change
    bool auctionComplete;
    RealEstateRegistry private realEstateRegistry;
    
    
    // Events to fire when change happens.
    event LogTopBidIncreased(address bidder, uint bidAmount);
    event LogAuctionResult(address winner, uint bidAmount);
    
    constructor(address _realEstateRegistryAddress, address _beneficiaryAddress, bytes32 _propertyId, uint256 _startingBid, uint256 _bidTime ) 
        public
    {
        addAddressToWhitelist(_beneficiaryAddress);
        require(_beneficiaryAddress != 0x0);
        beneficiaryAddress = _beneficiaryAddress;
        propertyId = _propertyId;
        startingDate = now;
        bidTime = _bidTime;
        endingDate = now + bidTime;
        startingBid = _startingBid;
        topBid = startingBid;
        auctionComplete = false;
        realEstateRegistry = RealEstateRegistry(_realEstateRegistryAddress);
    }
    
    function setTakeProfit(uint256 _takeProfit)
        onlyIfWhitelisted(msg.sender)
        public
    {
        autoCloseable = true;
        takeProfit = _takeProfit;
    }
    
    function bid()
        onlyIfPending()
        public
        payable
    {
       require(msg.value > topBid);
       if (topBidder != 0x0) {
           returnsPending[topBidder] += topBid;
       }
       topBidder = msg.sender;
       topBid = msg.value;
       emit LogTopBidIncreased(msg.sender, msg.value);
       if(autoCloseable && topBid >= takeProfit){
           internalCloseAuction();
       }
    }
    
    function withdraw()
        public
        returns(bool)
    {
        uint bidAmount = returnsPending[msg.sender];
        if(bidAmount > 0 && msg.sender == topBidder){
            returnsPending[msg.sender] = 0;
            if(!msg.sender.send(bidAmount)){
                returnsPending[msg.sender] = bidAmount;
                return false;
            }
        }
        return true;
    }
    
    function closeAuction() 
        onlyIfWhitelisted(msg.sender)
        public
    {
        internalCloseAuction();
    }
    
    function internalCloseAuction()
        private
    {
        require(!auctionComplete); 
        auctionComplete = true;
        emit LogAuctionResult(topBidder, topBid);
        beneficiaryAddress.transfer(topBid);
        returnsPending[topBidder] = 0;
        require(realEstateRegistry
                    .transferPropertyOwnershipSale(beneficiaryAddress, topBidder, propertyId)
        );
    }
    
    modifier onlyIfPending(){
        require(now <= endingDate && !auctionComplete);   
        _;
    }
    
}