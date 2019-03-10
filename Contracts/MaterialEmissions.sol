//This contact allows any address to claim any material has a given global warming potential
//The "claim" is simply a number which can represent the global warming potential of a material (ex fuel)
//"Carbon dioxide equivalency is a quantity that describes, for a given mixture and amount of greenhouse gas, the amount of CO2 that would have the same global warming potential (GWP), when measured over a specified timescale (generally, 100 years)."
//ex usage: A merchant could use this contact to calculate how much carbon tax to pay
//the signer could be a government agency or some other public entity

pragma solidity ^0.4.24;

contract MaterialEmissions{
    //emmision rate (ex How many tons C02 (or equivalent) the material emits per ton burned)
    mapping (address => mapping (address => uint256)) tonCO2Equivalent;
    //allows signer to unsign their previous claim for a material
    mapping (address => mapping (address => bool)) addressSignedMaterial;
    
    /**
    * @dev allows claims of a material's global warming potential
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
    function getRateSignedByAddress(address _signer, address _materialAddress) public view returns (uint256){
        if(addressSignedMaterial[msg.sender][_materialAddress] == true){
            return tonCO2Equivalent[_signer][_materialAddress];
        }
    }
    
    /**
    * @dev allows claimant to unsign/invalidate their claim
    * @param _materialAddress material in question
    */
    function unsignRate(address _materialAddress) public returns (bool){
        addressSignedMaterial[msg.sender][_materialAddress] = false;  
        return true;
    }
        
}
