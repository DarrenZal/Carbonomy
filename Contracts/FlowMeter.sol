//Records the net volume and quality of liquid hydrocarbons flowing through a pipe.
//This could be integrated with flow meters to record volumetric reporting used by various entities involved in the supply chain as well as outside entities like government agencies and the pubic.
//This system could be integrated with LACTs (Lease Automatic Custody Transfers) to provide for the automatic measurement, sampling, sale, and transfer of oil from the lease location into a pipeline.

pragma solidity ^0.5.00;
import "./SafeMath.sol";
import "./Fungible/Token.sol";

contract FlowMeter{
    using SafeMath for uint256;
    
    address public owner; //creator of this contract, could be owner of the meter 
    address public meter; //the only address allowed to measure.  Ideally the physical meter would have it's own Ethereum address to sign transactions in a secure enclave.
    //address public materials[]; //materials approved for measurement and transfer
    address public transferee; //This is an address which can automatically receive transfer the material as it flows out of the meter, such as a buyer who is always connected to the metering station outlflow
    address material;
    uint256 volumeMaterialMeasured;
    
    constructor(address _owner, address _meter, address _material) public {
        owner = _owner;
        meter = _meter;
        material = _material;
    }
    
    /**
    * @dev allows owner of the meter to set a transferee who can automatically receive transfer of material as it flows out of the meter
    * @param _transferee the address to which material can be transferred
    */
    function setTransferee(address _transferee) public {
        require(msg.sender == owner);
        transferee = _transferee;
    }
    
    /**
    * @dev measure a volume of material of a certain quality
    * @param _amount amount of material measured
    * @param _quality quality of the material.  This could represent purity, water content, density, etc.  This could be extended to an array of different qaulities (uint256[] _qualities)
    */
    function measure(uint256 _amount, uint256 _quality) public {
        require(msg.sender == meter);
        volumeMaterialMeasured = volumeMaterialMeasured.add(_amount);
        emit Measure(_amount, _quality);
    }
    
     /**
    * @dev measure a volume of material of a certain quality and automatically transfer it to transferee
    * @param _amount amount of material measured
    * @param _quality quality of the material.  This could represent purity, water content, density, etc.  This could be extended to an array of different qaulities (uint256[] _qualities)
    */
    function measureAndTransferAuto(uint256 _amount, uint256 _quality) public {
        require(msg.sender == meter);
        require(transferee != address(0));
        volumeMaterialMeasured = volumeMaterialMeasured.add(_amount);
        Token tokenInstance = Token(material);
        require(tokenInstance.allowance(owner, address(this)) >= _amount);
        require(tokenInstance.balanceOf(owner) >= _amount);
        tokenInstance.transferFrom(owner, transferee, _amount);
        emit MeasureAndTransfer(transferee, _amount, _quality);
    }
    
    event Measure(uint256 _volume, uint256 _quality);
    
    event MeasureAndTransfer(address _transferee, uint256 _amount, uint256 _quality);
    
    event MeasureAndSellOffChain(address _transferee, uint256 _amount, uint256 _quality);
}
