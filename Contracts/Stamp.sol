//This contract is intended to be used to keep track of excise taxes paid, like a digital excise Stamp
//For example when an oil refinery pays a carbon tax on gasoline, 
//this contract could 'stamp' their balance of gas, 
//the stamp would be transfered along with the gas when they sell the gas to a gas station.
//If tax is paid up stream, 'proof of tax paid' can be carried down the supply chain
//This could be particularly useful if a distributor is collecting materials from different suppliers, 
//some of which has had 

pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./Fungible/FungibleToken.sol";

contract Stamp{
    address owner;
    
    //account => token => stamp type => balance
    mapping (address => mapping (address => mapping (string => uint256))) stampBalance;
    
    function Stamp(address _caller) {
        owner = msg.sender;
    }
    
    function getOwner() public view returns (address){
        return owner;
    }
    
    /**
    * @dev returns an account's balance of a given token for which a specific tax has been paid
    * @param _account the address of the token balance
    * @param _token material which has been stamped
    * @param _stampType type of stamp, ex "carbonTax"
    */
    function getStampBalance(address _account, address _token, string _stampType) public view returns (uint256){
        return stampBalance[_account][_token][_stampType];
    }

    /**
    * @dev adds a stamp of given type to an account's balance of a given token
    * @param _account the address of the token balance
    * @param _token token/material getting the stamp
    * @param _stampType type of stamp, ex "carbonTax"
    */
    function stamp(address _account, address _token, string _stampType, uint256 _balance) public returns (bool){
        require(msg.sender == owner);
        stampBalance[_account][_token][_stampType] = SafeMath.add(stampBalance[_account][_token][_stampType], _balance);
        emit Stamped(_account, _token, _stampType, _balance);
        return true;
    }
    
    /**
    * @dev allows the stamp balance on a token to be transfered from one account to another, for ex when transferring that token
    * @param _accountFrom the address sending the stamp
    * @param _accountTo the address recieving the stamp
    * @param _token token/material which has the stamp
    * @param _stampType type of stamp, ex "carbonTax"
    */
    function transferStamp(address _accountFrom, address _accountTo, address _token, string _stampType, uint256 _balance) public returns (bool){
        require(msg.sender == owner);
        stampBalance[_accountFrom][_token][_stampType] = SafeMath.sub(stampBalance[_accountFrom][_token][_stampType], _balance);
        stampBalance[_accountTo][_token][_stampType] = SafeMath.add(stampBalance[_accountTo][_token][_stampType], _balance);
        emit TransferStamp(_accountFrom, _accountTo, _token, _stampType, _balance);
        return true;
    }
    
    event Stamped(address _account, address _token, string _stampType, uint256 _balance);
    event TransferStamp(address _accountFrom, address _accountTo, address _token, string _stampType, uint256 _balance);
}
