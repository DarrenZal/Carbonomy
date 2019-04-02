pragma solidity ^0.4.24;
import "../SafeMath.sol";
import "./FungibleToken.sol";

contract Materials{
    //true => this address represents an existing material
    mapping (address => bool) exists;
    //list of material contract addresses
    address[] public materialAddresses;

    /**
    * @dev returns list of material addresses
    */
    function getMaterials() public view returns (address[]){
        return materialAddresses;
    }

    /**
    * @dev allows adding a new material balance, allow duplicate name, symbol etc because address will be the unique ID
    */
    function addNewMaterial(string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public returns (address){
            FungibleToken newTokenAddress = new FungibleToken(address(this), 0, _tokenName, _decimalUnits, _tokenSymbol);
            require(!exists[newTokenAddress]);
            exists[newTokenAddress] = true;
            materialAddresses.push(newTokenAddress);
            materialAddresses.length++;
            return newTokenAddress;
    }

    /**
    * @dev allows deleting a material if there are no balances for that material
    */
    function removeMaterial(address _materialAddress, uint256 _materialIndex) public returns(bool) {
        require(exists[_materialAddress] == true);
        FungibleToken material = FungibleToken(_materialAddress);
        require(material.totalSupply() == 0);
        require(material.destruct(this) == true);
        removeMaterialAddress(_materialIndex, _materialAddress);
    }

    /**
    * @dev allows transforming one material to another
    */
    function transformMaterial(address _materialFrom, address _materialTo, uint256 _amountFrom, uint256 _amountTo, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public returns (bool){
        require(exists[_materialFrom] == true);
        FungibleToken material = FungibleToken(_materialFrom);
        require(material.balanceOf(msg.sender) >= _amountFrom);
        material.removeBalanceCustom(msg.sender, _amountFrom);
        address addressMaterialTo = _materialTo;
        FungibleToken materialTo;
        if(addressMaterialTo == address(0)){
            addressMaterialTo = addNewMaterial(_tokenName, _decimalUnits, _tokenSymbol);
            materialTo = FungibleToken(addressMaterialTo);
            materialTo.addBalanceCustom(msg.sender, _amountTo);
        } else {
            require(exists[_materialTo] == true);
            materialTo = FungibleToken(_materialTo);
            materialTo.addBalanceCustom(msg.sender, _amountTo);
        }
        TransformMaterial(_materialFrom, addressMaterialTo, _amountFrom, _amountTo);
    }

    /**
    * @dev allows deleting an address for a given material if balance is 0
    */
    function removeMaterialAddress(uint256 _materialIndex, address _materalAddress) internal returns(bool) {
        require(materialAddresses[_materialIndex] == _materalAddress);
        for (uint i = _materialIndex; i<materialAddresses.length-1; i++){
            materialAddresses[i] = materialAddresses[i+1];
        }
        delete materialAddresses[materialAddresses.length-1];
        materialAddresses.length--;
        return true;
    }


    event TransformMaterial(address _materialFrom, address _materialTo, uint256 _amountFrom, uint256 _amountTo);

}
