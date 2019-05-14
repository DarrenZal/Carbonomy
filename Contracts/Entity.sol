pragma solidity ^0.5.00;

contract Entity{
    mapping(address => entity) entities; //maps an address to an entity object
    address[] entityAddresses; //list of all registered addresses

    struct entity{
        bool registered;
        string businessName;
        string jurisdiction;
        uint index; //internal ID
    }

    /**
    * @dev allows entity registration
    */
    function register(string memory _businessName, string memory jurisdiction) public returns (bool){
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
    function unRegister(uint _index) public returns (bool){
        require(entities[msg.sender].registered == true);
        require(entityAddresses[_index] == msg.sender);
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
    function getJurisdiction(address _address) public view returns (string memory){
        return entities[_address].jurisdiction;
    }
    
    /**
    * @dev allows changing of entity jurisdiction
    */
    function changeJurisdiction(string memory _jurisdiction) public returns (string memory){
        entities[msg.sender].jurisdiction = _jurisdiction;
        return entities[msg.sender].jurisdiction;
    }

    /**
    * @dev returns entity business name
    */
    function getBusinessName(address _address) public view returns (string memory){
        return entities[_address].businessName;
    }
    
    /**
    * @dev allows changing of entity business name
    */
    function changeBusinessName(string memory _businessName) public returns (string memory){
        entities[msg.sender].businessName = _businessName;
        return entities[msg.sender].businessName;
    }

    /**
    * @dev returns registered entities
    */
    function getEntities() public view returns (address[] memory){
        return entityAddresses;
    }
}

