//Credits that can be used to offset carbon tax liability
//
//For ex Carbon Capture and Storage (CCS) might be eligible for credits which they can sell or use to offset a carbon tax
//tradeability would be useful when the entities sequestering carbon are different than the entities paying the carbon fee
//activities outside the tax base that reduce GHG emmisions could also be eligible for offsets/crdits
//
//A revenue agency could sign off that they accept these credits applied to tax liability
//The revenue agency might be the ones who create this contract and issue the credits, or simply certify by signing a claim

pragma solidity ^0.5.00;
import "./StandardToken.sol";
pragma experimental ABIEncoderV2;

contract CarbonCredits is StandardToken{
    /* Public variables of the token */
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //human readable name
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.
    address public owner;

    /**
    * @dev constructor
    * @param _tokenName human readable name
    * @param _decimalUnits //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    * @param _tokenSymbol //An identifier: eg CRD
    */
    constructor(
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
        ) public {
        owner = msg.sender;
        totSupply = 0;                        // Update total supply
        name = _tokenName;                      // Set the name for display purposes
        decimals = _decimalUnits;               // Amount of decimals for display purposes
        symbol = _tokenSymbol;                  // Set the symbol for display purposes
    }
    
    /**
    * @dev add to _address's balance
    * @param _address the address to add balance to
    * @param _amount how much to add
    */
    function addBalance(address _address, uint256 _amount, bytes memory _data) public returns (bool){
        require(msg.sender == owner);
        balances[_address] = SafeMath.add(balances[_address], _amount);
        totSupply = SafeMath.add(totSupply, _amount);
        emit AddBalance(_address, _amount, _data);
        return true;
    }
    
    /**
    * @dev remove from _address's balance
    * @param _address the address to add balance to
    * @param _amount how much to remove
    */
    function removeBalance(address _address, uint256 _amount, bytes memory _data) public returns (bool){
        require(msg.sender == owner);
        require(balances[_address] >= _amount);
        balances[_address] = SafeMath.sub(balances[_address], _amount);
        totSupply = SafeMath.sub(totSupply, _amount);
        emit RemoveBalance(_address, _amount, _data);
        return true;
    }
    
    /**
    * Event for recording issuing of carbon credits
    * @param _address the address to add balance to
    * @param _amount quantity to add
    * @param _data extra information ex: reason, explanation, category, type, etc
    */
    event AddBalance(address _address, uint256 _amount, bytes _data);
    
    /**
    * Event for recording removal of carbon credits
    * @param _address the address to add balance to
    * @param _amount quantity to remove
    * @param _data extra information ex: reason, explanation, category, type, etc
    */
    event RemoveBalance(address _address, uint256 _amount, bytes _data);
}
