//This contact allows any address to manage claims made on other contracts
//The claims are intented to be used for implementing a "carbon fee/tax"
//There are four types of claims supported
//  1. Fee for C02equivalent of emmissions (ex emmitting 1 ton C02 or equivalent costs a fee of $100)
//  2. Fee per unit of token (ex $100 fee per consumable unit of token 0x123..)
//  3. Fee for a material by name ("gasoline=>$20 per unit", "diesel=>$50 per unit", "methane=>$100 per unit", etc)
//  4. Claims of global warming potential concerning specific contracts/tokens/materials (ex Methane has more global warming potential than C02 per molecule)
//ex usage: A merchant could use this contact to calculate how much carbon tax to pay for the relevant jurisdiction
//the signer/claimer could be a government agency or some other public entity representing a legal jurisdiction

pragma solidity ^0.4.24;

contract WarmingFee{
    
//__claims of fees for C02equivalent of emmisions (ex emmitting 1 ton C02 or equivalent costs a fee of $100) ___

    //fee rate can represent the fee per tonCO2Equivalent
    mapping (address => uint256) C02EquivalentFee;
    //allows signer to unsign their previous claim
    mapping (address => bool) addressSignedC02EquivalentFee;
    
    /**
    * @dev allows siger to declare a fee for their jurisdiction (ex 1 ton C02 has a fee of $50)
    * @param _rate fee per tonC02Equivalent
    */
    function signC02EquivalentFee(uint256 _rate) returns (bool){
        C02EquivalentFee[msg.sender] = _rate;
        addressSignedC02EquivalentFee[msg.sender] = true;
        return true;
    }
    
    /**
    * @dev returns fee rate signed/declared by a given address
    * @param _signer claiment/signer 
    */
    function getC02EquivalentFeeSignedByAddress(address _signer) public view returns (uint256){
        if(addressSignedC02EquivalentFee[_signer] == true){
            return C02EquivalentFee[_signer];
        }
    }
    
    /**
    * @dev allows claimant to unsign/invalidate their claim of a fee rate (ex 1 ton C02 has a fee of $50)
    * @param _materialAddress material in question
    */
    function unsignC02EquivalentFee() public returns (bool){
        addressSignedC02EquivalentFee[msg.sender] = false;  
        return true;
    }
    
    
//__claims of fee per unit of token (ex $100 fee per consumable unit of token 0x123..) ___

    //fee rate can represent the fee per unit of material (ex $25 fee for every unit of consumable gasoline sold)
    mapping (address => mapping (address => uint256)) unitMaterialFee;
    //allows signer to unsign their previous claim
    mapping (address => mapping (address => bool)) addressSignedUnitMaterialFee;
    
    /**
    * @dev allows siger to declare a fee for their jurisdiction (ex 1 ton C02 has a fee of $50)
    * @param _rate fee per tonC02Equivalent
    */
    function signUnitMaterialFee(address _materialAddress, uint256 _rate) returns (bool){
        unitMaterialFee[msg.sender][_materialAddress] = _rate;
        addressSignedUnitMaterialFee[msg.sender][_materialAddress] = true;
        return true;
    }
    
    /**
    * @dev returns fee rate signed/declared by a given address
    * @param _signer claiment/signer 
    */
    function getUnitMaterialFeeSignedByAddress(address _signer, address _materialAddress) public view returns (uint256){
        if(addressSignedUnitMaterialFee[_signer][_materialAddress] == true){
            return unitMaterialFee[_signer][_materialAddress];
        }
    }
    
    /**
    * @dev allows claimant to unsign/invalidate their claim of a fee rate (ex 1 ton C02 has a fee of $50)
    * @param _materialAddress material in question
    */
    function unsignUnitMaterialFee(address _materialAddress) public returns (bool){
        addressSignedUnitMaterialFee[msg.sender][_materialAddress] = false;  
        return true;
    }
    
    
//__claims of fees for a material by name ("gasoline=>1", "diesel=>5", "methane=>25", etc) ___

    //fee rate can represent the fee of a specific material (ex "gasoline"=>$100 per Kg)
    mapping (address => mapping (bytes => uint256)) nameMaterialFee;
    //allows signer to unsign their previous claim
    mapping (address => mapping (bytes => bool)) addressSignedNameMaterialFee;
    
    /**
    * @dev allows claims of a material's fee (ex burnable "gasoline" has a fee of $100 per ton)
    * @param _materialAddress material in question
    * @param _rate global warming potential (relative to C02 for ex)
    */
    function signNameMaterialFeeR(bytes _materialName, uint256 _rate) returns (bool){
        nameMaterialFee[msg.sender][_materialName] = _rate;
        addressSignedNameMaterialFee[msg.sender][_materialName] = true;
        return true;
    }
    
    /**
    * @dev returns global warming potential claimed for a given material by a given address
    * @param _signer claiment/signer 
    * @param _materialAddress material in question
    */
    function getMaterialFee(address _signer, bytes _materialName) public view returns (uint256){
        if(addressSignedNameMaterialFee[msg.sender][_materialName] == true){
            return nameMaterialFee[_signer][_materialName];
        }
    }
    
    /**
    * @dev allows claimant to unsign/invalidate their claim of a material's global warming potential (ex gasoline is 1 ton C02 per gallon)
    * @param _materialAddress material in question
    */
    function unsignMaterialFee(address _materialAddress, bytes _materialName) public returns (bool){
        addressSignedNameMaterialFee[msg.sender][_materialName] = false;  
        return true;
    }
    
    
//__claims of global warming potential concerning specific contracts/tokens/materials___

    //emmision rate (ex How many tons C02 (or equivalent) the material emits per ton burned)
    mapping (address => mapping (address => uint256)) tonCO2Equivalent;
    //allows signer to unsign their previous claim for a material
    mapping (address => mapping (address => bool)) addressSignedMaterial;
    
    /**
    * @dev allows claims of a material's global warming potential by address (ex buring gasoline produces 1 ton C02 per gallon)
    * @param _materialAddress material in question
    * @param _rate global warming potential (relative to C02 for ex)
    */
    function signEmissionRate(address _materialAddress, uint256 _rate) returns (bool){
        tonCO2Equivalent[msg.sender][_materialAddress] = _rate;
        addressSignedMaterial[msg.sender][_materialAddress] = true;
        return true;
    }
    
    /**
    * @dev returns global warming potential claimed for a given material by a given address
    * @param _signer claiment/signer 
    * @param _materialAddress material in question
    */
    function getEmmisionRateSignedByAddress(address _signer, address _materialAddress) public view returns (uint256){
        if(addressSignedMaterial[msg.sender][_materialAddress] == true){
            return tonCO2Equivalent[_signer][_materialAddress];
        }
    }
    
    /**
    * @dev allows claimant to unsign/invalidate their claim of a material's global warming potential (ex gasoline is 1 ton C02 per gallon)
    * @param _materialAddress material in question
    */
    function unsignEmmisionRate(address _materialAddress) public returns (bool){
        addressSignedMaterial[msg.sender][_materialAddress] = false;  
        return true;
    }
        
}
