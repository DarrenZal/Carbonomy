pragma solidity ^0.5.00;
import "browser/EscrowERC20.sol"; //fungible
pragma experimental ABIEncoderV2;

contract EscrowERC20Factory {
    function addEscrowERC20(address[] memory _addresses, uint256 _amount, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees, address[] memory _feeCreditAddresses) public payable returns (address){
        EscrowERC20 newEscrowERC20 = (new EscrowERC20).value(msg.value)( _addresses, _amount, _price, _percentUpFront, _release, _transType, _feeTypes, _fees, _feeCreditAddresses);
        return address(newEscrowERC20);
    }
}
