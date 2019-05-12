//A marketplace/exchange for both fungible and non-fungible assets
//Orders can be signed offchain and executed on-chain

pragma solidity ^0.5.00;
import "../../Fungible/Token.sol"; //fungible
import "../../NonFungible/ERC721.sol"; //non-fungible
import "./ECDSA.sol";
pragma experimental ABIEncoderV2;

contract OffchainMarket{
    using ECDSA for bytes32;

    mapping(address => mapping(uint256 => bool)) seenNonces;

    function tradeERC20(address[2] memory _traders, address[2] memory _tokens, uint256[2] memory _quantities, string memory _feeTypes, uint256[] memory _fees, address[] memory _feeAddresses, address[] memory _feeCreditAddresses, string memory _transType, uint256 nonce, bytes memory signature) public payable{
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(abi.encodePacked(_traders, _tokens, _quantities, _feeTypes, _fees, _feeAddresses, _feeCreditAddresses, _transType, nonce, signature));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        
        
        // Verify that the message's signer is the owner of the order
        address signer = messageHash.recover(signature);
        //require both traders agree to the trade (either trader 1 signed and trader 2 is exeuting or vice versa)
        require((signer == _traders[0] && msg.sender == _traders[1]) || (signer == _traders[1] && msg.sender == _traders[0]));
        //nonce to mitigate replay attacks. We don’t want someone to to submit orders again to execute the same transaction again.
        require(!seenNonces[signer][nonce]);
        seenNonces[signer][nonce] = true;  
        processERC20Order( _traders, _tokens, _quantities, _feeTypes,  _fees,   _feeAddresses,  _feeCreditAddresses, _transType);
    }
    
    function tradeERC721(address[2] memory _traders, address[2] memory _tokens, uint256[2] memory _quantities, uint256[2] memory _tokenIDs, string memory _feeTypes, uint256[] memory _fees, address[] memory _feeAddresses, address[] memory _feeCreditAddresses, string memory _transType, uint256 nonce, bytes memory signature) public payable{
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(abi.encodePacked(_traders, _tokens, _quantities, _tokenIDs, _feeTypes, _fees, _feeAddresses, _feeCreditAddresses, _transType, nonce, signature));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        
        // Verify that the message's signer is the owner of the order
        address signer = messageHash.recover(signature);
        //require both traders agree to the trade (either trader 1 signed and trader 2 is exeuting or vice versa)
        require((signer == _traders[0] && msg.sender == _traders[1]) || (signer == _traders[1] && msg.sender == _traders[0]));
        //nonce to mitigate replay attacks. We don’t want someone to to submit orders again to execute the same transaction again.
        require(!seenNonces[signer][nonce]);
        seenNonces[signer][nonce] = true;  
        processERC721Order( _traders, _tokens, _quantities, _tokenIDs, _feeTypes,  _fees,   _feeAddresses,  _feeCreditAddresses, _transType);
    }
    
    function processERC20Order(address[2] memory _traders, address[2] memory _tokens, uint256[2] memory _quantities, string memory _feeTypes, uint256[] memory _fees, address[] memory _feeAddresses, address[] memory _feeCreditAddresses, string memory _transType) internal returns (bool){
        if(_tokens[0] != address(0)){
            //trader[0] is sending an ERC20 to trader[1] 
            require(Token(_tokens[0]).allowance(_traders[0], address(this)) >=  _quantities[0]);
            Token(_tokens[0]).transferFrom(_traders[0], _traders[1], _quantities[0]);
        } else {
            //trader[0] is sending Eth to trader[1], make sure trader[0] is msg.sender with msg.value payload
            require(_traders[0] ==  msg.sender && msg.value == _quantities[0]);
            address(uint160(_traders[0])).transfer(_quantities[0]);
        }
        if(_tokens[1] != address(0)){
            //trader[1] is sending an ERC20 to trader[0]
            require(Token(_tokens[1]).allowance(_traders[1], address(this)) >=  _quantities[1]);
            Token(_tokens[1]).transferFrom(_traders[1], _traders[0], _quantities[1]);
        } else {
            //trader[1] is sending Eth to trader[0], make sure trader[1] is msg.sender with msg.value payload
            require(_traders[1] ==  msg.sender && msg.value == _quantities[1]);
            address(uint160(_traders[1])).transfer(_quantities[1]);
        }
        if(_fees.length>0){
            //_feeAddresses also holds the address paying the fees
            require(_feeAddresses.length == _fees.length+1);
            address feePayer = _feeAddresses[0];
            for(uint i = 0; i < _fees.length; i++){
                address payable escrowTaxAddress = address(uint160(_feeAddresses[i+1]));
                if(_feeCreditAddresses[i] != address(0)){
                    //fee is paid in an ERC20
                    require(Token(_feeCreditAddresses[i]).allowance(feePayer, address(this)) >=  _fees[i]);
                    Token(_feeCreditAddresses[i]).transferFrom(feePayer, escrowTaxAddress, _fees[i]);
                } else {
                    escrowTaxAddress.transfer( _fees[i] );
                }
            }
        }
    }
    
    function processERC721Order(address[2] memory _traders, address[2] memory _tokens, uint256[2] memory _quantities, uint256[2] memory _tokenIDs, string memory _feeTypes, uint256[] memory _fees, address[] memory _feeAddresses, address[] memory _feeCreditAddresses, string memory _transType) internal returns (bool){
        if(_tokens[0] != address(0)){
            //trader[0] is sending an ERC721 to trader[1] 
            require(ERC721(_tokens[0]).getApproved(_tokenIDs[0]) == address(this));
            ERC721(_tokens[0]).transferFrom(_traders[0], _traders[1], _tokenIDs[0]);
        } else {
            //trader[0] is sending Eth to trader[1], make sure trader[0] is msg.sender with msg.value payload
            require(_traders[0] ==  msg.sender && msg.value == _quantities[0]);
            address(uint160(_traders[0])).transfer(_quantities[0]);
        }
        if(_tokens[1] != address(0)){
            //trader[1] is sending an ERC721 to trader[0]
            require(ERC721(_tokens[1]).getApproved(_tokenIDs[1]) == address(this));
            ERC721(_tokens[1]).transferFrom(_traders[1], _traders[0], _tokenIDs[0]);
        } else {
            //trader[1] is sending Eth to trader[0], make sure trader[1] is msg.sender with msg.value payload
            require(_traders[1] ==  msg.sender && msg.value == _quantities[1]);
            address(uint160(_traders[1])).transfer(_quantities[1]);
        }
        if(_fees.length>0){
            //_feeAddresses also holds the address paying the fees, _feeAddresses[0] is fee payer
            require(_feeAddresses.length == _fees.length+1);
            address feePayer = _feeAddresses[0];
            for(uint i = 0; i < _fees.length; i++){
                address payable escrowTaxAddress = address(uint160(_feeAddresses[i+1]));
                if(_feeCreditAddresses[i] != address(0)){
                    //fee is paid in an ERC20
                    require(Token(_feeCreditAddresses[i]).allowance(feePayer, address(this)) >=  _fees[i]);
                    Token(_feeCreditAddresses[i]).transferFrom(feePayer, escrowTaxAddress, _fees[i]);
                } else {
                    escrowTaxAddress.transfer( _fees[i] );
                }
            }
        }
    }
    
    function stringSplitArray(string memory _input) public view returns (string[8] memory){
        string[8] memory result;
        string memory residual = _input;
        uint ctr = 0;
        while(bytes(residual).length > 0){
            (result[ctr],residual) = stringSplitComma(residual);
            ctr++;
        }
        return result;
    }
    
    function stringSplitComma(string memory _test) internal pure returns (string memory, string memory){
        bytes memory strBytes = bytes(_test);
        uint ptr;
        for(ptr = 0; ptr < strBytes.length; ptr++) {
            if(strBytes[ptr] == ",") break;
        }
        bytes memory result = new bytes(ptr);
        for(uint j = 0; j < ptr; j++) {
            result[j] = strBytes[j];
        }
        bytes memory result2 = "";
        if(strBytes.length-ptr > 1){
        result2 = new bytes(strBytes.length-ptr-1);
        for(uint i=0; i< strBytes.length-ptr-1; i++){
            result2[i] = strBytes[ptr+i+1];
        }
        }
        return (string(result),string(result2));
    }

}
   
