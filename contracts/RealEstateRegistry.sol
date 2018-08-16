pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/Whitelist.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract RealEstateRegistry is Whitelist, Pausable, Destructible{
    
    struct Property{
        bool exists;
        
    }
    
    mapping (address => mapping(bytes32 => Property)) private registry;
    
    constructor() public{
        addAddressToWhitelist(msg.sender);
        
    }
    
    function giveOwnership(address user, bytes32 propertyId)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        returns (bool)
    {
        require(!isOwnerOf(user, propertyId));  
        registry[user][propertyId] = Property({
            exists: true
        });
        return true;
        
    }
    
    function amIOwnerOf(bytes32 propertyId)
        public 
        view
        returns(bool)
    {
        return isOwnerOf(msg.sender, propertyId);    
    }
    
    function isOwnerOf(address user, bytes32 propertyId)
        public
        view
        returns (bool)
    {
        return registry[user][propertyId].exists;
    }
    
   
    
    /* Fallback function */
    function () public {}
    
}