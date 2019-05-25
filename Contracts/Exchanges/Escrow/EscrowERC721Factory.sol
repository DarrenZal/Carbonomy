pragma solidity ^0.5.00;
import "./EscrowERC721.sol"; //fungible
pragma experimental ABIEncoderV2;

contract EscrowERC721Factory {
    function addEscrowERC721(address[] memory _addresses, uint256 _tokenID, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees, address[] memory _feeCreditAddresses) public payable returns (address){
        EscrowERC721 newEscrowERC721 = (new EscrowERC721).value(msg.value)( _addresses, _tokenID, _price, _percentUpFront, _release, _transType, _feeTypes, _fees, _feeCreditAddresses);
        return address(newEscrowERC721);
    }
}
