pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/Whitelist.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract RealEstateRegistry is Whitelist, Pausable, Destructible{
    using SafeMath for uint;
    
    enum Category {Apartment, MultiFamilyHouse, TerracedHouse, Condominium, Cooperative, Vilas, Other}
    
    struct ResidentialRealEstate {
        bool exists;
        Category category;
    }
    
    struct PropertyCollection{
        bool exists;
        uint numberOfProperties;
        mapping(bytes32 => ResidentialRealEstate) residencies;
    }
    
    mapping (address => PropertyCollection) private ownerRegistry;
    mapping (bytes32 => address) private propertyRegistry;
    
    constructor() public{
        addAddressToWhitelist(msg.sender);
        
    }
    
    function givePropertyOwnership(address user, bytes32 propertyId, uint _category )
        onlyIfWhitelisted(msg.sender)
        onlyValidCategory(_category)
        whenNotPaused
        public
        returns (bool)
    {
        if(!ownerRegistry[user].exists){
            ownerRegistry[user] = PropertyCollection({
                exists: true,
                numberOfProperties: 0
            });
        }
        require(!isOwnerOf(user, propertyId));  
        internalGivePropertyOwnership(user, propertyId, _category);
        return true;
    }
    
    function internalGivePropertyOwnership(address to, bytes32 propertyId, uint _category)
        private
    {
        ownerRegistry[to].residencies[propertyId] = ResidentialRealEstate({
            exists: true,
            category: Category(_category)
        });
        propertyRegistry[propertyId] = to;
    }
    
    function removePropertyOwnership(address user, bytes32 propertyId)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
    {
        require(isOwnerOf(user, propertyId));
        internalRemovePropertyOwnership(user, propertyId);
    }
    
    function internalRemovePropertyOwnership(address user, bytes32 propertyId)
        private
    {
        delete ownerRegistry[user].residencies[propertyId];
        propertyRegistry[propertyId] = 0x0;
    }
    
    function transferPropertyOwnership(address from, address to, bytes32 propertyId)
        whenNotPaused
        public
    {
        require(isOwnerOf(msg.sender, propertyId) || hasRole(msg.sender, "whitelist"));
        Category _category = ownerRegistry[from].residencies[propertyId].category;
        internalRemovePropertyOwnership(from, propertyId);
        internalGivePropertyOwnership(to, propertyId,uint( _category));
    }
    
    function whoIsOwnerOf(bytes32 propertyId)
        public
        returns(address)
    {
        return propertyRegistry[propertyId];
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
        return ownerRegistry[user].residencies[propertyId].exists;
    }
    
   
    /* Modifiers */
    modifier onlyValidCategory(uint _category){
        require((uint(Category.Other) >= _category));
        _;
    }
    
    /* Fallback function */
    function () public {}
    
}