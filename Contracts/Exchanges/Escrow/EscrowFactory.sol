pragma solidity ^0.5.00;
pragma experimental ABIEncoderV2;

contract EscrowERC20Factory{
    function addEscrowERC20(address[] memory _addresses, uint256 _amount, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees) public payable returns (address);
}
contract EscrowERC721Factory{
    function addEscrowERC721(address[] memory _addresses, uint256 _tokenID, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees) public payable returns (address);
}

contract EscrowFactory{
    address[] contractsERC20;
    address[] contractsERC721;
    
    function addEscrowERC20(address _factoryAddress, address[] memory _addresses, uint256 _amount, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees) public payable returns (address){
        EscrowERC20Factory instanceEscrowERC20Factory = EscrowERC20Factory(_factoryAddress);
        address escrowAddress = instanceEscrowERC20Factory.addEscrowERC20.value(msg.value)(_addresses, _amount, _price, _percentUpFront, _release, _transType, _feeTypes, _fees);
        contractsERC20.push(address(escrowAddress));
        return address(escrowAddress);
    }
    
    function addEscrowERC721(address _factoryAddress, address[] memory  _addresses, uint256 _tokenID, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees) public payable returns (address){
        EscrowERC721Factory instanceEscrowERC721Factory = EscrowERC721Factory(_factoryAddress);
        address escrowAddress = instanceEscrowERC721Factory.addEscrowERC721.value(msg.value)(_addresses, _tokenID, _price, _percentUpFront, _release, _transType, _feeTypes, _fees);
        contractsERC721.push(address(escrowAddress));
        return address(escrowAddress);
    }
    
    function getEscrowsERC20() public view returns (address[] memory){
        return contractsERC20;
    }
    
    function getEscrowsERC721() public view returns (address[] memory){
        return contractsERC721;
    }
}   
