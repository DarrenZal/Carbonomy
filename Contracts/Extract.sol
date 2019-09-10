//This contract allows entites to extract materials, which are represented as fungible tokens
//Ex: An oil company could use this to record extraction of oil

pragma solidity ^0.5.00;
import "./SafeMath.sol";
import "./Well.sol";
import "./Fungible/Materials.sol";
import "./Fungible/FungibleToken.sol";

interface Entity{
    /**
     * @dev returns registration data for a entity given the address
     * @param _entityAddress entity address
     *
     */
    function isEntityRegistered(address  _entityAddress) external view returns (bool);
}

contract Extract is Well, Materials{
    address public creator;
    
    constructor(address _creator) public {
        creator = _creator;
    }
    
    /**
    * @dev record oil extraction from a well
    * @param _identityContract the contract which keeps track of registered entities (allowed to ectract)
    * @param _wellID the ID of the well
    * @param _tokenName Human readable name/description of the material
    * @param _decimalUnits Amount of decimals for display purposes
    * @param _tokenSymbol Symbol for display purposes
    * @param _amount quantity of extraction
    */
    function recordExtractionNewMaterial(address _identityContract, uint256 _wellID, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol, uint256 _amount) public returns (bool){
        well storage thisWell = wells[_wellID];
        require(thisWell.owner == msg.sender);
        require(thisWell.active == true);
        bool entityRegistered = Entity(_identityContract).isEntityRegistered(msg.sender);
        require(entityRegistered == true);
        address materialAddress = addNewMaterial( _tokenName,  _decimalUnits,  _tokenSymbol);
        FungibleToken thisMaterial = FungibleToken(materialAddress);
        //below should call the function as owner, allowing adding to the balance of the address of the caller if this function (msg.sender)
        thisMaterial.addBalanceCustom(msg.sender, _amount);
        thisWell.materials.push(materialAddress);
        thisWell.extracted.push(_amount);
        thisWell.materials.length++;
        thisWell.extracted.length++;
        thisWell.previouslyExtracted[materialAddress] == true;
        emit RecordExtraction(msg.sender, _wellID, materialAddress, _amount);
        return true;
    }
    
    /**
    * @dev record oil extraction from a well
    * @param _identityContract the contract which keeps track of registered entities (allowed to ectract)
    * @param _wellID address of the well
    * @param _materialAddress address of the material extracted
    * @param _wellMaterialIndex index of the material within the well's ledger of materials it has extracted before
    * @param _amount quantity of extraction
    */
    function recordExtractionOldMaterial(address _identityContract, uint256 _wellID, address _materialAddress, uint _wellMaterialIndex, uint256 _amount) public returns (bool){
        well storage thisWell = wells[_wellID];
        require(thisWell.owner == msg.sender);
        require(thisWell.active == true);
        bool entityRegistered = Entity(_identityContract).isEntityRegistered(msg.sender);
        require(entityRegistered == true);
        if(thisWell.previouslyExtracted[_materialAddress] == true){ //this well has extracted this material before.
            require(thisWell.materials[_wellMaterialIndex] == _materialAddress);
            FungibleToken thisMaterial = FungibleToken(_materialAddress);
            //below should call the function as owner, allowing adding to the balance of the address of the caller if this function (msg.sender)
            thisMaterial.addBalanceCustom(msg.sender, _amount);
            thisWell.extracted[_wellMaterialIndex] += _amount;
        } else {
            thisWell.materials.push(_materialAddress);
            thisWell.extracted.push(_amount);
            thisWell.materials.length++;
            thisWell.extracted.length++;
            thisWell.previouslyExtracted[_materialAddress] = true;
        }
        emit RecordExtraction(msg.sender, _wellID, _materialAddress, _amount);
        return true;
    }
    
    /**
    * Event for recording a well de-activation
    * @param _entity the entity recording extraction 
    * @param _wellID the well ID
    * @param _materialAddress the address of material contract
    * @param _volume volume extracted
    */
    event RecordExtraction(address _entity, uint256 _wellID, address _materialAddress, uint256 _volume);
    
}
