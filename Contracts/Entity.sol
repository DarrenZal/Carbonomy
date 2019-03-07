pragma solidity ^0.4.24;

contract Entity{
mapping(address => entity) entities; //maps an address to an entity object
address[] entityAddresses; //list of all registered addresses

struct entity{
bool registered;
bytes businessName;
bytes jurisdiction;
}

/**
* @dev allows entity registration
*/
function register(bytes _businessName, bytes jurisdiction) public returns (bool){
require(entities[msg.sender].registered == false);
entities[msg.sender].businessName = _businessName;
entities[msg.sender].jurisdiction = jurisdiction;
entities[msg.sender].registered = true;
entityAddresses.push(msg.sender);
return entities[msg.sender].registered;
}

/**
* @dev allows entity un-registration
*/
function unRegister() public returns (bool){
require(entities[msg.sender].registered == true);
entities[msg.sender].registered = false;
}

/**
* @dev returns entity registration
*/
function isRegistered(address _address) public view returns (bool){
return entities[_address].registered;
}

/**
* @dev returns entity jurisdiction
*/
function getJurisdiction(address _address) public view returns (bytes){
return entities[_address].jurisdiction;
}

/**
* @dev allows changing of entity jurisdiction
*/
function changeJurisdiction(bytes _jurisdiction) public view returns (bytes){
entities[msg.sender].jurisdiction = _jurisdiction;
return entities[msg.sender].jurisdiction;
}

/**
* @dev returns entity business name
*/
function getBusinessName(address _address) public view returns (bytes){
return entities[_address].businessName;
}

/**
* @dev allows changing of entity business name
*/
function changeBusinessName(bytes _businessName) public view returns (bytes){
entities[msg.sender].businessName = _businessName;
return entities[msg.sender].businessName;
}

/**
* @dev returns registered entities
*/
function getEntities() public view returns (address[]){
return entityAddresses;
}
}
