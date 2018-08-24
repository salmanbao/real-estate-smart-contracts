pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/Whitelist.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./PropertySale.sol";

contract PropertySaleAuction is PropertySale, Whitelist, Pausable, Destructible{
    
    bytes32 propertyId;
    uint256 startingDate;
    uint256 endingDate;
    
    uint256 startingBid;
    bool autoCloseable;
    uint256 autoCloseBid;
    uint256 topBid;
    address topBidder;
    
    constructor(bytes32 _propertyId, uint256 _startingBid, uint256 _startingDate, uint256 _endingDate) public{
        addAddressToWhitelist(msg.sender);
        propertyId = _propertyId;
        startingDate = _startingDate;
        endingDate = _endingDate;
        startingBid = _startingBid;
    }
    
    function start() public{
        
    }
    function end() public{
        
    }
}