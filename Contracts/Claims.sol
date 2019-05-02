//This contact allows any address to manage claims made on other contracts
//The claims are intented to be used for implementing a "carbon fee/tax"
//There are five types of claims supported
//  1. Fee for C02equivalent of emmissions (ex emmitting 1 ton C02 or equivalent costs a fee of $100)
//  2. Fee per unit of token (ex $100 fee per consumable unit of token 0x123..)
//  3. Fee for a material by name ("gasoline=>$20 per unit", "diesel=>$50 per unit", "methane=>$100 per unit", etc)
//  4. Claims of global warming potential concerning specific contracts/tokens/materials (ex Methane has more global warming potential than C02 per molecule)
//  5. claims of carbon credits which are eligible for offseting tax liability (signer could be revenue agency)
//ex usage: A merchant could use this contact to calculate how much carbon tax to pay for the relevant jurisdiction
//the signer/claimer could be a government agency or some other public entity representing a legal jurisdiction

pragma solidity ^0.5.00;

contract Claims{

//_1._claims of fees for C02equivalent of emmisions (ex emmitting 1 ton C02 or equivalent costs a fee of $100) ___

    //fee rate can represent the fee per tonCO2Equivalent
    mapping (address => uint256) C02EquivalentFee;
    //allows signer to unsign their previous claim
    mapping (address => bool) addressSignedC02EquivalentFee;

    /**
    * @dev allows siger to declare a fee for their jurisdiction (ex 1 ton C02 has a fee of $50)
    * @param _rate fee per tonC02Equivalent
    */
    function signC02EquivalentFee(uint256 _rate) public returns (bool){
        C02EquivalentFee[msg.sender] = _rate;
        addressSignedC02EquivalentFee[msg.sender] = true;
        emit SignC02EquivalentFee(msg.sender, _rate);
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
    */
    function unsignC02EquivalentFee() public returns (bool){
        addressSignedC02EquivalentFee[msg.sender] = false;
        return true;
    }

    event SignC02EquivalentFee(address _signer, uint256 _rate);


//_2._claims of fee per unit of token (ex $100 fee per consumable unit of token 0x123..) ___

    //fee rate can represent the fee per unit of material (ex $25 fee for every unit of consumable gasoline sold)
    mapping (address => mapping (address => uint256)) unitMaterialFee;
    //allows signer to unsign their previous claim
    mapping (address => mapping (address => bool)) addressSignedUnitMaterialFee;

    /**
    * @dev allows siger to declare a fee for their jurisdiction (ex 1 ton C02 has a fee of $50)
    * @param _rate fee per tonC02Equivalent
    */
    function signUnitMaterialFee(address _materialAddress, uint256 _rate) public returns (bool){
        unitMaterialFee[msg.sender][_materialAddress] = _rate;
        addressSignedUnitMaterialFee[msg.sender][_materialAddress] = true;
        emit SignUnitMaterialFee(msg.sender, _materialAddress, _rate);
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

    event SignUnitMaterialFee(address _signer, address _materialAddress, uint256 _rate);


//_3._claims of fees for a material by name ("gasoline=>1", "diesel=>5", "methane=>25", etc) ___

    //fee rate can represent the fee of a specific material (ex "gasoline"=>$100 per Kg)
    mapping (address => mapping (bytes => uint256)) nameMaterialFee;
    //allows signer to unsign their previous claim
    mapping (address => mapping (bytes => bool)) addressSignedNameMaterialFee;

    /**
    * @dev allows claims of a material's fee (ex burnable "gasoline" has a fee of $100 per ton)
    * @param _materialName material in question
    * @param _rate global warming potential (relative to C02 for ex)
    */
    function signNameMaterialFee(bytes memory _materialName, uint256 _rate) public returns (bool){
        nameMaterialFee[msg.sender][_materialName] = _rate;
        addressSignedNameMaterialFee[msg.sender][_materialName] = true;
        emit SignNameMaterialFee(msg.sender, _materialName, _rate);
        return true;
    }

    /**
    * @dev returns global warming potential claimed for a given material by a given address
    * @param _signer claiment/signer
    * @param _materialName material in question
    */
    function getNameMaterialFee(address _signer, bytes memory _materialName) public view returns (uint256){
        if(addressSignedNameMaterialFee[msg.sender][_materialName] == true){
            return nameMaterialFee[_signer][_materialName];
        }
    }

    /**
    * @dev allows claimant to unsign/invalidate their claim of a material's global warming potential (ex gasoline is 1 ton C02 per gallon)
    * @param _materialName material in question
    */
    function unsignNameMaterialFee(bytes memory _materialName) public returns (bool){
        addressSignedNameMaterialFee[msg.sender][_materialName] = false;
        return true;
    }

    event SignNameMaterialFee(address _signer, bytes _materialName, uint256 _rate);


//_4._claims of global warming potential concerning specific contracts/tokens/materials___

    //emmision rate (ex How many tons C02 (or equivalent) the material emits per ton burned)
    mapping (address => mapping (address => uint256)) tonCO2Equivalent;
    //allows signer to unsign their previous claim for a material
    mapping (address => mapping (address => bool)) addressSignedMaterial;

    /**
    * @dev allows claims of a material's global warming potential by address (ex buring gasoline produces 1 ton C02 per gallon)
    * @param _materialAddress material in question
    * @param _rate global warming potential (relative to C02 for ex)
    */
    function signEmissionRate(address _materialAddress, uint256 _rate) public returns (bool){
        tonCO2Equivalent[msg.sender][_materialAddress] = _rate;
        addressSignedMaterial[msg.sender][_materialAddress] = true;
        emit SignEmmisionRate(msg.sender, _materialAddress, _rate);
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

    event SignEmmisionRate(address _signer, address _materialAddress, uint256 _rate);

//_5._claims of which carbon credits are eligible for offseting tax liability

    //signer => carbon credit ledger address => recognized/supported/accepted
    mapping (address => mapping (address => bool)) acceptedCredits;

    /**
    * @dev allows claims of which carbon credits are eligible for offset tax liability
    * @param _creditsAddress carbon credit token address
    */
    function signCredits(address _creditsAddress) public returns (bool){
        acceptedCredits[msg.sender][_creditsAddress] = true;
        emit SignCarbonCredits(msg.sender, _creditsAddress);
        return true;
    }

    /**
    * @dev allows claimant to unsign/invalidate their claim that specific carbon credits are recognized/supported/accepted
    * @param _creditsAddress carbon credit token address
    */
    function unsignCredits(address _creditsAddress) public returns (bool){
        addressSignedMaterial[msg.sender][_creditsAddress] = false;
        emit unSignCarbonCredits(msg.sender, _creditsAddress);
        return true;
    }

    /**
    * @dev returns true if the _signer accepts _creditsAddress tokens to offset tax liability
    * @param _signer claiment/signer
    * @param _creditsAddress credits in question
    */
    function getCreditsSignature(address _signer, address _creditsAddress) public view returns (uint256){
        return tonCO2Equivalent[_signer][_creditsAddress];
    }

    event unSignCarbonCredits(address _signer, address _creditsAddress);
    event SignCarbonCredits(address _signer, address _creditsAddress);

}
