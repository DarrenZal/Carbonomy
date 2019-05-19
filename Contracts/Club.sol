pragma solidity ^0.4.24;

contract Club{
    mapping(address => bool) member;
    address[] memberList;
    uint256 carbonPrice; //price of emmitting 1Kg C02 equivalent

    constructor(uint256 _price){
        member[msg.sender] = true;
        memberList.push(msg.sender);
        memberList.length++;
        carbonPrice = _price;
    }

    function join() public returns (bool){
        require(member[msg.sender] == false);
        member[msg.sender] = true;
        memberList.push(msg.sender);
        memberList.length++;
        return true;
    }



}









