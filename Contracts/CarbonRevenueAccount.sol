//This is a sample 'carbon fee and dividend' revenue account.  The concept is very loosely based on the Energy Innovation and Carbon Dividend Act of 2019 (H.R. 763)
//It is meant to collect fees paid for goods and servises which emit carbon (petroleum fuel etc) and refund a portion of that revenue to registered users
//payouts are triggered by calling the payout() function, which can be called by anyone after 30 days since the last payout. 
//the payouts are capped by a number set when the contract is created
//if a payout is triggered and there is more than enough funds to give everyone a full payout, excess funds are routed to a secondary revenue account address

pragma solidity ^0.5.00;
import "./SafeMath.sol";

contract CarbonRevenueAccount{ 
    using SafeMath for uint256;
    //owner could be a central government agency or a decentralized DAO. 
    //this code could be amended to allow the owner to approve applicants to prevent Sybil attacks
    address owner;
    //Secondary revenue account, if there is more than enough money to pay everyone the payoutCap, the excess funds are routed to this account
    address payable secondaryAccount; 
    uint256 secondaryAccountRate; //how much will be transfered to the secondary account if there are funds available
    uint256 lastPayoutDate;
    uint256 payoutInterval = 2592000; //2592000 = 30 days in seconds
    uint256 payoutQuantity; //Amount of revenue payout to all registered accounts 
    uint256 payoutCap; //cost of how much one round of payouts would cost
    
    mapping(address => entity) entities; 
    address[] entityAddresses; //list of all registered addresses

    struct entity{
        bool registered;
        uint index; //internal ID
    }
    
    /**
    * @dev sets parameters for this contract upon deploy
    * @param _owner could be a central government agency or a decentralized DAO. 
    * @param _payoutCap cost of how much one round of payouts would cost
    * @param _secondaryAccount Secondary revenue account, if there is more than enough money to pay everyone the payoutCap, the excess funds are routed to this account
    * @param _secondaryAccountRate how much will be transfered to the secondary account if there are funds available
    */
    constructor(address _owner, uint256 _payoutCap, address payable _secondaryAccount, uint256 _secondaryAccountRate) public {
        owner = _owner;
        payoutCap = _payoutCap;
        secondaryAccount = _secondaryAccount;
        secondaryAccountRate = _secondaryAccountRate;
    }
    
    /**
    * @dev Revenue can be refunded at a specified amount to all registered users at a specified time interval
    */
    function payout() public returns (bool){
        //require a month has passed since last payout
        require(now >= lastPayoutDate.add(payoutInterval));
        //if there is not enough for a full payout, give all resistered accounts an equal share of (this) balance
        uint256 payoutQuantity = payoutCap;
        uint256 excessfunds = 0;
        if(address(this).balance.div(entityAddresses.length) <= payoutCap){
            payoutQuantity = address(this).balance.div(entityAddresses.length);
        } else { //there are excess funds to route to secondary revenue account 
            excessfunds = address(this).balance.sub(payoutQuantity.mul(entityAddresses.length));
            if(excessfunds > secondaryAccountRate){
                excessfunds = secondaryAccountRate;
            }
        }
        for(uint i = 0; i < entityAddresses.length; i++){
            //double check that the address is registered, all addresses in entityAddresses are registered, when they are un-registered, they are removed from the list
            if(entities[entityAddresses[i]].registered){
                address(uint160(entityAddresses[i])).transfer(payoutQuantity);
            }
        }
        secondaryAccount.transfer(excessfunds);
        lastPayoutDate = now;
        return true;
    }

    /**
    * @dev allows entity registration
    */
    function register() public returns (bool){
        require(entities[msg.sender].registered == false);
        entities[msg.sender].registered = true;
        entityAddresses.push(msg.sender);
        payoutCap = payoutCap.add(payoutQuantity);
        return entities[msg.sender].registered;
    }

    /**
    * @dev allows entity un-registration
    * @param _index internal identifier of the account in question
    */
    function unRegister(uint _index) public returns (bool){
        require(msg.sender == owner || msg.sender == entityAddresses[_index]);
        require(entities[msg.sender].registered == true);
        if (removeEntity(_index) == false) return false; //remove from list of registered entities
        payoutCap = payoutCap.sub(payoutQuantity);
        entities[msg.sender].registered = false;
    }

    /**
    * @dev returns entity registration
    * @param _address address of the account in question
    */
    function isRegistered(address _address) public view returns (bool){
        require(msg.sender == owner || msg.sender == _address);
        return entities[_address].registered;
    }


    /**
    * @dev returns registered entities
    */
    function getEntities() public view returns (address[] memory){
        require(msg.sender == owner);
        return entityAddresses;
    }
    
    /**
    * @dev removes entity from list of registered entities
    * @param _index the identifier of the Entity to remove
    */
    function removeEntity(uint _index) internal returns (bool){
        require(_index < entityAddresses.length);
        require(_index < entityAddresses.length);
        for (uint i = _index; i<entityAddresses.length-1; i++){
            entityAddresses[i] = entityAddresses[i+1];
        }
        delete entityAddresses[entityAddresses.length-1];
        entityAddresses.length--;
        return true;
    }

}
