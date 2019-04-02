/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/
pragma solidity ^0.4.4;

import "./StandardToken.sol";

contract FungibleToken is StandardToken {

    /**
    * @dev allow selfDestruct if there are no balances (free up space in the blockchain!)
    * @param _destructor the address to send residual funds to
    */
    function destruct(address _destructor) public returns (bool){
        require(totalSupply == 0);
        selfdestruct(_destructor);
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //eg Oil, gasoline, plastic #2
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.
    address owner;

    function FungibleToken(
        address _caller,
        uint256 _amount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        owner = msg.sender;
        balances[_caller] = _amount;               // Give the creator all initial tokens
        totalSupply = _amount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
    * @dev add to caller's balance
    * @param _amount how much to add
    */
    function addBalance(uint256 _amount) returns (bool){
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);
        totalSupply = SafeMath.add(totalSupply, _amount);
    }

    /**
    * @dev allows transformation of one token to another in one transaction in combo with removeBalance()
    * @param _account address to add balance to
    * @param _amount how much to add
    */
    function addBalanceCustom(address _account, uint256 _amount) returns (bool){
        require(msg.sender == owner);
        balances[_account] = SafeMath.add(balances[_account], _amount);
        totalSupply = SafeMath.add(totalSupply, _amount);
    }

    /**
    * @dev allows removal of balance
    * @param _amount how much to remove
    */
    function removeBalance(uint256 _amount) returns (bool){
        require(SafeMath.sub(balances[msg.sender], _amount) >= 0);
        require(SafeMath.sub(totalSupply, _amount) >= 0);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        totalSupply = SafeMath.sub(totalSupply, _amount);
    }

    /**
    * @dev allows transformation of one token to another in one transaction in combo with addBalance()
    * @param _account address to remove balance from
    * @param _amount how much to remove
    */
    function removeBalanceCustom(address _account, uint256 _amount) returns (bool){
        require(msg.sender == owner);
        require(SafeMath.sub(balances[_account], _amount) >= 0);
        require(SafeMath.sub(totalSupply, _amount) >= 0);
        balances[_account] = SafeMath.sub(balances[_account], _amount);
        totalSupply = SafeMath.sub(totalSupply, _amount);
    }

    /**
    * @dev Approves and then calls the receiving contract
    * @param _spender address of allowed spender
    * @param _value how much to approve
    * @param _extraData extra data as bytes
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}
