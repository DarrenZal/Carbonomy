//This contract can create new fungible tokens (ERC20) with addNewMaterial()
//Adding new materials is important to accomodate the different types of raw materials extracted around the world
//This contract can transform any ERC20 into another ERC20 with transformMaterial()
//transformation is important to oil and gas refining where raw material inputs are chemically transformed into new outputs

pragma solidity ^0.5.00;
import "../SafeMath.sol";
import "./FungibleToken.sol";

contract Materials{
    //if true then this address represents an existing material
    mapping (address => bool) exists;
    //list of material contract addresses
    address[] public materialAddresses;

    /**
    * @dev returns list of material addresses
    */
    function getMaterials() public view returns (address[] memory ){
        return materialAddresses;
    }

    /**
    * @dev allows adding a new material balance, allow duplicate name, symbol etc because address will be the unique ID
    */
    function addNewMaterial(string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public returns (address){
            FungibleToken newToken = new FungibleToken(address(this), 0, _tokenName, _decimalUnits, _tokenSymbol);
            address newTokenAddress = address(newToken);
            require(!exists[newTokenAddress]);
            exists[newTokenAddress] = true;
            materialAddresses.push(newTokenAddress);
            materialAddresses.length++;
            return newTokenAddress;
    }

    /**
    * @dev allows transforming one material to another
    */
    function transformMaterial(address _materialFrom, address _materialTo, uint256 _amountFrom, uint256 _amountTo, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public returns (bool){
        address addressMaterialTo = _materialTo;
        FungibleToken materialTo;
        if(exists[_materialFrom]){ 
            //The token being transformed exists as a Material, so we can decrease the supply using removeBalanceCustom
            FungibleToken material = FungibleToken(_materialFrom);
            require(material.balanceOf(msg.sender) >= _amountFrom);
            material.removeBalanceCustom(msg.sender, _amountFrom);
        } else { 
            //The token being transformed must be a regular ERC20 which has approved this contract to transfer _amountFrom in order to lock it up
            Token tokenFrom = Token(_materialFrom);
            require(_amountFrom <= tokenFrom.balanceOf(msg.sender));
            require(tokenFrom.allowance( msg.sender,  address(this)) >= _amountFrom);
            tokenFrom.transferFrom(msg.sender, address(this), _amountFrom);
        }
        if(addressMaterialTo == address(0)){
            addressMaterialTo = addNewMaterial(_tokenName, _decimalUnits, _tokenSymbol);
            materialTo = FungibleToken(addressMaterialTo);
            materialTo.addBalanceCustom(msg.sender, _amountTo);
        } else {
            require(exists[_materialTo] == true);
            materialTo = FungibleToken(_materialTo);
            materialTo.addBalanceCustom(msg.sender, _amountTo);
        }
        emit TransformMaterial(_materialFrom, addressMaterialTo, _amountFrom, _amountTo);
    }


    event TransformMaterial(address _materialFrom, address _materialTo, uint256 _amountFrom, uint256 _amountTo);

}
