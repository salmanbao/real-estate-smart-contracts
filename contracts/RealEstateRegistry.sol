pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/Whitelist.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./PropertySaleAuction.sol";

/**
@title RealEstateRegistry
@author Abdelhamid Bakhta
@notice RealEstateRegistry is a smart contract 
@notice for managing a decentralized real estate system
*/
contract RealEstateRegistry is Whitelist, Pausable, Destructible{
    using SafeMath for uint;
    
    enum Category {Apartment, MultiFamilyHouse, TerracedHouse, Condominium, Cooperative, Vilas, Other}
    
    address constant none = 0x0;
    
    struct ResidentialRealEstate {
        bool exists;
        Category category;
    }
    
    struct PropertyCollection{
        bool exists;
        uint numberOfProperties;
        mapping(bytes32 => ResidentialRealEstate) residencies;
    }
    
    struct PropertyInfo{
        bool exists;
        address owner;
        PropertySaleAuction sale;
    }
    
    // registry of owned properties per user
    mapping (address => PropertyCollection) private ownerRegistry;
    // registry of managed properties
    mapping (bytes32 => PropertyInfo) private propertyRegistry;
    
    // events
    /// @notice triggered when a property ownership is assigned to a user
    event LogPropertyOwnershipAssigned(address indexed to, bytes32 indexed propertyId);
    /// @notice triggered when a property ownership is removed to a user
    event LogPropertyOwnershipRemoved(address indexed to, bytes32 indexed propertyId);
    /// @notice triggered when a property ownership is transferred from a user to another user
    event LogPropertyOwnershipTransferred(address indexed from, address indexed to, bytes32 indexed propertyId);
    event LogSaleStarted(address indexed owner, bytes32 propertyId, uint256 startingBid, uint256 bidTime);
    
    
    constructor() public{
        addAddressToWhitelist(msg.sender);
        
    }
    
    /**
    * @dev Allows the whitelisted users to assign the ownership of a property to a given user
    * @param propertyId The identifier of the property.
    * @param _newOwner The address to assign property ownership to.
    * @param _category The category of property.
    */
    function assignPropertyOwnership(address _newOwner, bytes32 propertyId, uint _category )
        onlyIfWhitelisted(msg.sender)
        onlyValidCategory(_category)
        whenNotPaused
        public
        returns (bool)
    {
        if(!ownerRegistry[_newOwner].exists){
            ownerRegistry[_newOwner] = PropertyCollection({
                exists: true,
                numberOfProperties: 0
            });
        }
        require(propertyRegistry[propertyId].owner == none);
        require(!isOwnerOf(_newOwner, propertyId));  
        internalAssignPropertyOwnership(_newOwner, propertyId, _category);
        emit LogPropertyOwnershipAssigned(_newOwner, propertyId);
        return true;
    }
    
    function internalAssignPropertyOwnership(address to, bytes32 propertyId, uint _category)
        private
    {
        ownerRegistry[to].residencies[propertyId] = ResidentialRealEstate({
            exists: true,
            category: Category(_category)
        });
        ownerRegistry[to].numberOfProperties++;
        if(!propertyRegistry[propertyId].exists){
            propertyRegistry[propertyId] = PropertyInfo({
                exists: true,
                owner: to,
                sale: PropertySaleAuction(0)
            });
        }else{
            propertyRegistry[propertyId].owner = to;
            propertyRegistry[propertyId].sale = PropertySaleAuction(0);
        }

    }
    
    function removePropertyOwnership(address user, bytes32 propertyId)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
    {
        require(isOwnerOf(user, propertyId));
        internalRemovePropertyOwnership(user, propertyId);
        emit LogPropertyOwnershipRemoved(user, propertyId);
    }
    
    function internalRemovePropertyOwnership(address user, bytes32 propertyId)
        private
    {
        delete ownerRegistry[user].residencies[propertyId];
        ownerRegistry[user].numberOfProperties--;
        propertyRegistry[propertyId].owner = none;
    }
    
    function transferPropertyOwnership(address from, address to, bytes32 propertyId)
        whenNotPaused
        public
    {
        require(isOwnerOf(msg.sender, propertyId) || hasRole(msg.sender, "whitelist"));
        Category _category = ownerRegistry[from].residencies[propertyId].category;
        internalRemovePropertyOwnership(from, propertyId);
        internalAssignPropertyOwnership(to, propertyId,uint( _category));
        emit LogPropertyOwnershipTransferred(from, to , propertyId);
    }
    
    function sell(bytes32 propertyId, uint256 startingBid, uint256 bidTime)
        onlyIfNotOnSale(propertyId)
        public
    {
        require(isOwnerOf(msg.sender, propertyId));
        PropertySaleAuction auction = new PropertySaleAuction(msg.sender, propertyId, startingBid, bidTime);
        propertyRegistry[propertyId].sale = auction;
        emit LogSaleStarted(msg.sender, propertyId, startingBid, bidTime);
    }
    
    /**
    * @dev Gets the owner of the specified property.
    * @param propertyId The address to query the owner.
    * @return An address representing the owner of the passed property.
    */
    function whoIsOwnerOf(bytes32 propertyId)
        public
        view
        returns(address)
    {
        return propertyRegistry[propertyId].owner;
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
        return ownerRegistry[user].residencies[propertyId].exists && propertyRegistry[propertyId].owner == user;
    }
    
   
    /* Modifiers */
    modifier onlyValidCategory(uint _category){
        require((uint(Category.Other) >= _category));
        _;
    }
    
    modifier onlyIfNotOnSale(bytes32 propertyId){
        require(propertyRegistry[propertyId].sale == PropertySaleAuction(0x0));
        _;
    }
    
    /* Fallback function */
    function () public {}
    
}