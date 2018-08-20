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
    
    mapping (address => PropertyCollection) private registry;
    
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
        if(!registry[user].exists){
            registry[user] = PropertyCollection({
                exists: true,
                numberOfProperties: 0
            });
        }
        require(!isOwnerOf(user, propertyId));  
        internalGiveOwnership(user, propertyId, _category);
        return true;
    }
    
    function internalGiveOwnership(address to, bytes32 propertyId, uint _category)
        private
    {
        registry[to].residencies[propertyId] = ResidentialRealEstate({
            exists: true,
            category: Category(_category)
        });
    }
    
    function removePropertyOwnership(address user, bytes32 propertyId)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
    {
        require(isOwnerOf(user, propertyId));
        internalRemoveOwnership(user, propertyId);
    }
    
    function internalRemoveOwnership(address user, bytes32 propertyId)
        private
    {
        delete registry[user].residencies[propertyId];
    }
    
    function transferPropertyOwnership(address from, address to, bytes32 propertyId)
        whenNotPaused
        public
    {
        require(isOwnerOf(msg.sender, propertyId) || hasRole(msg.sender, "whitelist"));
        Category _category = registry[from].residencies[propertyId].category;
        internalRemoveOwnership(from, propertyId);
        internalGiveOwnership(to, propertyId,uint( _category));
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
        return registry[user].residencies[propertyId].exists;
    }
    
   
    /* Modifiers */
    modifier onlyValidCategory(uint _category){
        require((uint(Category.Other) >= _category));
        _;
    }
    
    /* Fallback function */
    function () public {}
    
}