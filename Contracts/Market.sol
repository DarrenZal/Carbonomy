//A marketplace/exchange for both fungible and non-fungible assets

pragma solidity ^0.4.25;
import "browser/Token.sol"; //fungible
import "browser/ERC721.sol"; //non-fungible
pragma experimental ABIEncoderV2;

contract Market{
    address thisAddress = address(this);

    // object representing an escrow contract
    struct escrow{
        address tokenAddress;
        uint256 tokenID;  //token ID for ERC721
        bool buyerSigned;
        bool sellerSigned;
        bool buyerUnSigned;
        bool sellerUnSigned;
        bool buyerReleased;
        bool sellerReleased;
        address seller;
        address buyer;
        address arbiter;
        uint256 price;
        uint256 quantity;
        uint256 percentUpFront;
        string transType; //transaction type ex: 'resale' or 'consumption'
        string[] feeTypes;
        uint256[] fees;
        address[] feeAddresses;
        bool buyerDisputed;
        bool sellerDisputed;
        string tokenType; //ERC20, ERC721 etc
    }

    // an array to hold all active escrow contracts
    escrow[] escrowContracts;

    /**
    * @dev Creates escrow contract, either buyer or seller can create one
    * @param _addresses addresses of token contract (_addresses[0]), buyer (_addresses[1]), seller (_addresses[2]), arbiter (_addresses[3]), and feeAddresses (_address[4+]). *leave counterparty blank to allow anyone to sign as counterparty
    * @param _price total cost of the deal
    * @param _amount total ownership tokens of the deal
    * @param _percentUpFront percent of total cost to be paid to seller once both parties sign
    * @param _release if the creator releases up front, the counterparty is free to complete the exchange by signing and releasing 
    * @param _transType transaction type ex: 'resale' or 'consumption'
    * @param _feeTypes types of fees ex ['carbon fee', 'consumption tax']
    * @param _fees fee amounts ex [5, 7]
    */
    function createEscrowERC20(address[] _addresses, uint256 _amount, uint256 _price, uint256 _percentUpFront, bool _release, string _transType, string[] _feeTypes, uint256[] _fees) public payable returns (bool){
        require(0 <= _percentUpFront && _percentUpFront <= 100);
        Token tokenInstance = Token(_addresses[0]);
        //if sender is seller
        if(msg.sender == _addresses[2]){
            require(tokenInstance.allowance( _addresses[2],  thisAddress) >= _amount);
            require(tokenInstance.balanceOf(_addresses[2]) >= _amount);
            tokenInstance.transferFrom(_addresses[1], thisAddress, _amount);
            escrowContracts.push(escrow(_addresses[0], 0, false, true, false, false, false, _release, _addresses[2], _addresses[1], _addresses[3], _price, _amount, _percentUpFront, _transType, new string[](0), new uint256[] (0), new address[](0), false, false, "ERC20"));
            addTaxData(escrowContracts.length-1, _addresses, _feeTypes, _fees);
            emit EscrowSigned(escrowContracts.length-1, _addresses[2]);
        } else {
            require(msg.sender == _addresses[1]);
            uint256 totalFees = 0;
            for(uint i = 0; i < _fees.length; i++){
                totalFees = SafeMath.add(totalFees, _fees[i]);
            }
            require(msg.value == SafeMath.add(_price,totalFees));
            escrowContracts.push(escrow(_addresses[0], 0, false, true, false, false, _release, false, _addresses[2], _addresses[1], _addresses[3], _price, _amount, _percentUpFront, _transType, new string[](0), new uint256[] (0), new address[](0), false, false, "ERC20"));
            addTaxData(escrowContracts.length-1, _addresses, _feeTypes, _fees);
            emit EscrowSigned(escrowContracts.length-1, _addresses[1]);
        }
    }
    
    /**
    * @dev adds the fee data to the escrow contract, to split up the function to avoid "stack too deep"
    */
    function addTaxData(uint256 _index, address[] _addresses, string[] _feeTypes, uint256[] _fees) internal returns (bool){
        address[] feeAddresses;
        for(uint i = 4; i < _addresses.length; i++){
            feeAddresses.push(_addresses[i]);
        }
        escrowContracts[_index].feeTypes = _feeTypes;
        escrowContracts[_index].fees = _fees;
        escrowContracts[_index].feeAddresses = feeAddresses;
    }
    
    /**
    * @dev Creates escrow contract, either buyer or seller can create one
    * @param _tokenID ID of ERC721 token
    * @param _addresses addresses of token contract (_addresses[0]), buyer (_addresses[1]), seller (_addresses[2]), and arbiter (_addresses[3]). *leave counterparty blank to allow anyone to sign as counterparty
    * @param _price total cost of the deal
    * @param _percentUpFront percent of total cost to be paid to seller once both parties sign
    * @param _transType transaction type ex: 'resale' or 'consumption'
    * @param _feeTypes types of fees ex ['carbon fee', 'consumption tax']
    * @param _fees fee amounts ex [5, 7]
    */
    function createEscrowERC721(address[] _addresses, uint256 _tokenID, uint256 _price, uint256 _percentUpFront, bool _release, string _transType, string[] _feeTypes, uint256[] _fees) public payable returns (bool){
        require(0 <= _percentUpFront && _percentUpFront <= 100);
        ERC721 tokenInstance = ERC721(_addresses[0]);
        if(msg.sender == _addresses[2]){
            require(tokenInstance.getApproved(_tokenID) == thisAddress);
            //**make sure this contract can accept NFT
            tokenInstance.transferFrom(_addresses[2], thisAddress, _tokenID);
            escrowContracts.push(escrow(_addresses[0], _tokenID, false, true, false, false, false, _release, _addresses[2], _addresses[1], _addresses[3], _price, 1, _percentUpFront, _transType, new string[](0), new uint256[](0), new address[](0), false, false, "ERC721"));
            addTaxData(escrowContracts.length-1, _addresses, _feeTypes, _fees);
            emit EscrowSigned(escrowContracts.length-1, _addresses[2]);
        } else {
            require(msg.sender == _addresses[1]);
            uint256 totalFees = 0;
            for(uint i = 0; i < _fees.length; i++){
                totalFees = SafeMath.add(totalFees, _fees[i]);
            }
            require(msg.value == SafeMath.add(_price,totalFees));
            escrowContracts.push(escrow(_addresses[0], _tokenID, false, true, false, false, false, _release, _addresses[2], _addresses[1], _addresses[3], _price, 1, _percentUpFront, _transType, new string[](0), new uint256[](0), new address[](0), false, false, "ERC721"));
            emit EscrowSigned(escrowContracts.length-1, _addresses[1]);
        }
    }

    /**
    * @dev completes the escrow contract, transfering payment to seller and ownership to buyer, both parties must release
    * @param _index specifies which escrow contract to release
    */
    function releaseEscrow(uint256 _index) public returns (bool){
        require(_index < escrowContracts.length);
        address tokenAddress = escrowContracts[_index].tokenAddress;
        //if buyer has signed and not unsigned, mark buyerReleased as True
        if((escrowContracts[_index].buyer == msg.sender || msg.sender == address(this)) && escrowContracts[_index].buyerSigned == true && escrowContracts[_index].buyerUnSigned == false){
            escrowContracts[_index].buyerReleased = true;
        //if seller has signed and not unsigned, mark sellerReleased as True
        } else if((escrowContracts[_index].buyer == msg.sender || msg.sender == address(this)) && escrowContracts[_index].sellerSigned == true && escrowContracts[_index].sellerUnSigned == false){
            escrowContracts[_index].sellerReleased = true;
        }
        if(escrowContracts[_index].buyerReleased && escrowContracts[_index].sellerReleased){
            require(escrowContracts[_index].buyerDisputed == false && escrowContracts[_index].sellerDisputed == false);
            if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC20")){
                 Token(tokenAddress).transfer(escrowContracts[_index].buyer, escrowContracts[_index].quantity);
            } else if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC721")){
                ERC721(tokenAddress).transferFrom(escrowContracts[_index].seller, escrowContracts[_index].buyer, escrowContracts[_index].tokenID);
            }
            //transfer funds to the seller minus how much was paid up front
            escrowContracts[_index].seller.transfer(SafeMath.div(SafeMath.mul(100-escrowContracts[_index].percentUpFront,escrowContracts[_index].price),100));
            //pay fees, which were collected when the buyer signed
            if(escrowContracts[_index].fees.length > 0){
                for(uint i = 0; i < escrowContracts[_index].fees.length; i++){
                    address escrowTaxAddress = escrowContracts[_index].feeAddresses[i];
                    escrowTaxAddress.transfer( escrowContracts[_index].fees[i] );
                } 
            }
            escrow thisContract = escrowContracts[_index];
            emit EscrowFinalized(escrowContracts[_index].tokenAddress, escrowContracts[_index].tokenID, thisContract.seller, thisContract.buyer, thisContract.price, thisContract.quantity, thisContract.percentUpFront, thisContract.transType, thisContract.feeTypes, thisContract.fees, thisContract.feeAddresses, thisContract.tokenType);
            removeEscrow(_index);
        }
        return true;
    }
    
    /**
    * @dev Allows buyer and seller to unRelease Escrow
    * @param _index specifies which escrow contract to unRelease
    */
    function unReleaseEscrow(uint256 _index) public returns (bool){
        require(_index < escrowContracts.length);
        if(escrowContracts[_index].buyer == msg.sender && escrowContracts[_index].buyerReleased == true){
            escrowContracts[_index].buyerReleased = false;
        } else if(escrowContracts[_index].seller == msg.sender && escrowContracts[_index].sellerReleased == true){
            escrowContracts[_index].sellerReleased = false;
        }
        return true;
    }

    /**
    * @dev If an address has created and signed the escrow contract putting in Alice's name as the other party, Alice will need to sign to validate the contract
    * Or, if the other party created an escrow contract with a blank address (address(0)), Alice can fill that slot and sign.
    * The parameters of the contract are passed in to make sure the sender is signing the correct contract
    * @param _index specifies which escrow contract to sign
    * @param _addresses [tokenAddress, seller, buyer, arbiter, taxAddresses(could be multiple)]
    * @param _nums [tokenID, price, quantity, percentUpFront, fees(could be multiple)]
    * @param _bools [buyerSigned, sellerSigned, buyerUnSigned, sellerUnSigned, buyerReleased, sellerReleased, buyerDisputed,sellerDisputed]
    * @param _strings [transType, tokenType, feeTypes(could be multiple)]
    * 
    */
    function signEscrow(uint256 _index, address[] _addresses, uint256[] _nums, bool[8] _bools, string[] _strings) public payable returns (bool){
        escrow storage thisEscrow = escrowContracts[_index];
        require(_index < escrowContracts.length);
        require(thisEscrow.tokenAddress == _addresses[0] && thisEscrow.seller == _addresses[1] && thisEscrow.buyer == _addresses[2] && escrowContracts[_index].arbiter == _addresses[3]);
        for(uint i = 4; i < _addresses.length; i++){
            require(thisEscrow.feeAddresses[i] == _addresses[i]);
        }
        require(thisEscrow.tokenID == _nums[0] && escrowContracts[_index].price == _nums[1] && escrowContracts[_index].quantity == _nums[2] && escrowContracts[_index].percentUpFront == _nums[3]);
        for(uint j = 4; i < _addresses.length; j++){
            require(thisEscrow.fees[j] == _nums[j]);
        }
        require(thisEscrow.buyerSigned == _bools[0] && thisEscrow.sellerSigned == _bools[1] && thisEscrow.buyerUnSigned == _bools[2] && thisEscrow.sellerUnSigned == _bools[3] && thisEscrow.buyerReleased == _bools[4] && thisEscrow.sellerReleased == _bools[5] && thisEscrow.buyerDisputed == _bools[6] && thisEscrow.sellerDisputed == _bools[7]);
        require(keccak256(thisEscrow.transType) == keccak256(_strings[0]) && keccak256(thisEscrow.tokenType) == keccak256(_strings[1]));
        for(uint k = 2; k < _addresses.length; k++){
            require(keccak256(escrowContracts[_index].feeTypes[k]) == keccak256(_strings[k]));
        }
        if((thisEscrow.buyer == msg.sender || thisEscrow.buyer == address(0)) && thisEscrow.buyerSigned == false){
            if(thisEscrow.fees.length > 0){
                uint256 totalFees = 0;
                for(uint l = 0; l < thisEscrow.fees.length; l++){
                    totalFees = SafeMath.add(totalFees, thisEscrow.fees[l]);
                }
                require(msg.value == SafeMath.add(thisEscrow.price, totalFees));
            } else {
                require(msg.value == thisEscrow.price);
            }
            thisEscrow.buyer = msg.sender;
            if(thisEscrow.percentUpFront > 0 ){
                thisEscrow.seller.transfer(SafeMath.div(SafeMath.mul(thisEscrow.percentUpFront,thisEscrow.price),100));
            }
            thisEscrow.buyerSigned = true;
            emit EscrowSigned(_index, msg.sender);
            return true;
        } else if((thisEscrow.seller == msg.sender || thisEscrow.seller == address(0)) && thisEscrow.sellerSigned == false){
            require(msg.value == 0);
            address tokenAddress = escrowContracts[_index].tokenAddress;
            if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC20")){
                 require(escrowContracts[_index].quantity <= Token(tokenAddress).balanceOf(msg.sender));
                 require(Token(tokenAddress).allowance( msg.sender,  thisAddress) >= escrowContracts[_index].quantity);
                 Token(tokenAddress).transferFrom(msg.sender, thisAddress, thisEscrow.quantity);
            } else if (keccak256(thisEscrow.tokenType) == keccak256("ERC721")){
                 require(ERC721(tokenAddress).getApproved( thisEscrow.tokenID) == thisAddress);
                 ERC721(tokenAddress).transferFrom(msg.sender, thisAddress, thisEscrow.tokenID);
            }
            thisEscrow.seller = msg.sender;
            if(thisEscrow.percentUpFront > 0 ){
                thisEscrow.seller.transfer(SafeMath.div(SafeMath.mul(thisEscrow.percentUpFront,thisEscrow.price),100));
            }
            thisEscrow.sellerSigned = true;
            emit EscrowSigned(_index, msg.sender);
            return true;
        }
        else return false;
    }

    //sign and finalize in same transaction
    /**
    * @dev Allows an address to sign and finalize escrow in the same transaction
    * The parameters of the contract are passed in to make sure the sender is signing the correct contract
    * @param _index specifies which escrow contract to sign
    * @param _addresses [tokenAddress, seller, buyer, arbiter, feeAddress]
    * @param _nums [tokenID, price, quantity, percentUpFront, fees]
    * @param _bools [buyerSigned, sellerSigned, buyerUnSigned, sellerUnSigned, buyerReleased, sellerReleased, buyerDisputed,sellerDisputed]
    * @param _strings [transType, tokenType, feeTypes]
    */
    function signAndReleaseEscrow(uint256 _index, address[] _addresses, uint256[] _nums, bool[8] _bools, string[] _strings) public payable returns (bool){
        if(matchEscrow( _index,  _addresses,  _nums,  _bools, _strings) != true) return false;
        escrow thisContract = escrowContracts[_index];
        address tokenAddress = thisContract.tokenAddress;
        if((thisContract.buyer == msg.sender || thisContract.buyer == address(0)) && thisContract.buyerSigned == false){
            if(thisContract.fees.length > 0){
                require(msg.value == SafeMath.add(thisContract.price, getFeeTotal(_index)));
            } else {
                require(msg.value == thisContract.price);
            }
            escrowContracts[_index].buyer = msg.sender;
            if(escrowContracts[_index].percentUpFront > 0 ){
                escrowContracts[_index].seller.transfer(SafeMath.div(SafeMath.mul(thisContract.percentUpFront,thisContract.price),100));
            }
            escrowContracts[_index].buyerSigned = true;
            emit EscrowSigned(_index, msg.sender);
        } else if((thisContract.seller == msg.sender || thisContract.seller == address(0)) && thisContract.sellerSigned == false){
            require(msg.value == 0);
            if (keccak256(thisContract.tokenType) == keccak256("ERC20")){
                 require(thisContract.quantity <= Token(tokenAddress).balanceOf(msg.sender));
                 Token thisToken = Token(tokenAddress);
                 require(thisToken.allowance( msg.sender,  thisAddress) >= escrowContracts[_index].quantity);
                 thisToken.transferFrom(msg.sender, thisAddress, thisContract.quantity);
            } else if (keccak256(thisContract.tokenType) == keccak256("ERC721")){
                ERC721 thisERC721 = ERC721(tokenAddress);
                 require(thisERC721.getApproved( thisContract.tokenID) == thisAddress);
                 thisERC721.transferFrom(msg.sender, thisAddress, thisContract.tokenID);
            }
            thisContract.seller = msg.sender;
            if(thisContract.percentUpFront > 0 ){
                thisContract.seller.transfer(SafeMath.div(SafeMath.mul(thisContract.percentUpFront,thisContract.price),100));
            }
            thisContract.sellerSigned = true;
            emit EscrowSigned(_index, msg.sender);
        } else return false;

        //Finalize escrow
        if(thisContract.buyer == msg.sender){
            thisContract.buyerReleased = true;
        //if seller has signed and not unsigned, mark sellerReleased as True
        } else if(thisContract.buyer == msg.sender){
            escrowContracts[_index].sellerReleased = true;
        } else return false;
        releaseEscrow(_index);
    }
    
    /**
    * @dev Allows the buyer and seller to unsign a contract, it also automatically deletes the contract once both have unsigned
    * this allows buyer and seller to delete the contract without arbitration
    * @param _index specifies which escrow contract to unSign
    */
    function unSignEscrow(uint256 _index) public returns (bool){
        require(_index < escrowContracts.length);
        require(escrowContracts[_index].buyer == msg.sender || escrowContracts[_index].seller == msg.sender);
        address tokenAddress = escrowContracts[_index].tokenAddress;
        uint256 totalFees = 0;
        for(uint m = 0; m < escrowContracts[_index].fees.length; m++){
            totalFees = SafeMath.add(totalFees, escrowContracts[_index].fees[m]);
        } 
        if(escrowContracts[_index].buyer == msg.sender && escrowContracts[_index].buyerSigned == true){
            escrowContracts[_index].buyerUnSigned = true;
            if (escrowContracts[_index].buyerSigned == false){
                //seller never signed, can refund buyer his money (minus percent paid up front) and delete the contract
                //If tax was put in escrow up front, refund the tax as well
                if(escrowContracts[_index].fees.length > 0){
                    escrowContracts[_index].buyer.transfer(SafeMath.add(totalFees, SafeMath.div(SafeMath.mul(100-escrowContracts[_index].percentUpFront,escrowContracts[_index].price),100)));
                } else {
                    escrowContracts[_index].buyer.transfer(SafeMath.div(SafeMath.mul(100-escrowContracts[_index].percentUpFront,escrowContracts[_index].price),100));
                }
                removeEscrow(_index);
                return true;
            }
        } else if (escrowContracts[_index].seller == msg.sender && escrowContracts[_index].sellerSigned == true){
            escrowContracts[_index].sellerUnSigned = true;
            if (escrowContracts[_index].buyerSigned == false){
                //buyer never signed, can refund seller his shares and delete the contract
                if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC20")){
                    Token(tokenAddress).transfer(escrowContracts[_index].seller, escrowContracts[_index].quantity);
                } else if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC721")){
                    ERC721(tokenAddress).transferFrom(thisAddress, escrowContracts[_index].seller, escrowContracts[_index].tokenID);
                }
                removeEscrow(_index);
                return true;
            }
        } else return false;
        if (escrowContracts[_index].buyerUnSigned == true && escrowContracts[_index].sellerUnSigned == true){
            //both parties have signed but then unsigned, can refund both and delete contract
            if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC20")){
                Token(tokenAddress).transfer(escrowContracts[_index].seller, escrowContracts[_index].quantity);
            } else if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC721")){
                ERC721(tokenAddress).transferFrom(thisAddress, escrowContracts[_index].seller, escrowContracts[_index].tokenID);
            }
            //Buyer paid percentUpFront when they signed, so remove that from the refund
            //If tax was put in escrow up front, refund the tax as well
            escrowContracts[_index].buyer.transfer(SafeMath.add(totalFees,SafeMath.div(SafeMath.mul(100-escrowContracts[_index].percentUpFront,escrowContracts[_index].price),100)));
            removeEscrow(_index);
        }
        return true;
    }
 

    function matchEscrow(uint256 _index, address[] _addresses, uint256[] _nums, bool[8] _bools, string[] _strings) internal returns (bool){
        require(_index < escrowContracts.length);
        require(escrowContracts[_index].tokenAddress == _addresses[0] && escrowContracts[_index].seller == _addresses[1] && escrowContracts[_index].buyer == _addresses[2] && escrowContracts[_index].arbiter == _addresses[3]);
        for(uint i = 4; i < _addresses.length; i++){
            require(escrowContracts[_index].feeAddresses[i] == _addresses[i]);
        }
        require(escrowContracts[_index].tokenID == _nums[0] && escrowContracts[_index].price == _nums[1] && escrowContracts[_index].quantity == _nums[2] && escrowContracts[_index].percentUpFront == _nums[3]);
        for(uint j = 4; i < _addresses.length; j++){
            require(escrowContracts[_index].fees[j] == _nums[j]);
        }
        require(escrowContracts[_index].buyerSigned == _bools[0] && escrowContracts[_index].sellerSigned == _bools[1] && escrowContracts[_index].buyerUnSigned == _bools[2] && escrowContracts[_index].sellerUnSigned == _bools[3] && escrowContracts[_index].buyerReleased == _bools[4] && escrowContracts[_index].sellerReleased == _bools[5] && escrowContracts[_index].buyerDisputed == _bools[6] && escrowContracts[_index].sellerDisputed == _bools[7]);
        require(keccak256(escrowContracts[_index].transType) == keccak256(_strings[0]) && keccak256(escrowContracts[_index].tokenType) == keccak256(_strings[1]));
        for(uint k = 2; k < _addresses.length; k++){
            require(keccak256(escrowContracts[_index].feeTypes[k]) == keccak256(_strings[k]));
        }
        return true;
    }

    /**
    * @dev Buyer or Seller can dispute an escrow contract if they have signed
    * @param _index specifies which escrow contract to dispute
    */
    function disputeEscrow(uint256 _index) public returns (bool){
        require(_index < escrowContracts.length);
        //only buyer or seller can dispute a contract, and onyl if they have signed it
        if(escrowContracts[_index].buyer == msg.sender){
            require(escrowContracts[_index].buyerSigned == true);
            require(escrowContracts[_index].buyerDisputed == false);
            escrowContracts[_index].buyerDisputed = true;
        } else if (escrowContracts[_index].seller == msg.sender){
            require(escrowContracts[_index].sellerSigned == true);
            require(escrowContracts[_index].sellerDisputed == false);
            escrowContracts[_index].sellerDisputed = true;
        } else return false;
        return true;
    }

    /**
    * @dev Buyer or Seller can unDispute an escrow contract if they have disputed
    * @param _index specifies which escrow contract to unDispute
    */
    function unDisputeEscrow(uint256 _index) public returns (bool){
        require(_index < escrowContracts.length);
        //only buyer or seller can dispute a contract, and onyl if they have signed it
        if(escrowContracts[_index].buyer == msg.sender){
            require(escrowContracts[_index].buyerDisputed == true);
            escrowContracts[_index].buyerDisputed = false;
        } else if (escrowContracts[_index].seller == msg.sender){
            require(escrowContracts[_index].sellerDisputed == true);
            escrowContracts[_index].sellerDisputed = false;
        } else return false;
        return true;
    }

    // For ERC721, amountToBuyer and amountToSeller should be 1 and 0 or vice versa, since it is one unique item
    /**
    * @dev Arbiter can arbitrate an escrow contract, divying up the ownership tokens and funds held in the escrow contract between buyer and seller
    * @param _index specifies which escrow contract to arbitrate
    * @param _amountToSeller Amount of ownership tokens to give seller
    * @param _amountToBuyer Amount of ownership tokens to give buyer
    * @param _paymentToSeller funds to give seller
    * @param _paymentToBuyer funds to give seller
    */
    function arbitrateEscrow(uint256 _index, uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer) public returns (bool){
        escrow storage thisEscrow = escrowContracts[_index];
        require(_index < escrowContracts.length);
        require(msg.sender == thisEscrow.arbiter);
        require(thisEscrow.buyerDisputed == true || thisEscrow.sellerDisputed == true);
        if(escrowContracts[_index].buyerDisputed == false){
            require(msg.sender != thisEscrow.seller);
        } else if (thisEscrow.sellerDisputed == false){
            require(msg.sender != thisEscrow.buyer);
        }
        require(thisEscrow.buyerSigned == true && thisEscrow.sellerSigned == true);
        if(escrowContracts[_index].fees.length > 0){
            uint256 totalFees = 0;
            for(uint i = 0; i < escrowContracts[_index].fees.length; i++){
                totalFees = SafeMath.add(totalFees, escrowContracts[_index].fees[i]);
            } 
            require(_paymentToSeller + _paymentToBuyer == SafeMath.add(SafeMath.div(SafeMath.mul(100-thisEscrow.percentUpFront,thisEscrow.price),100),totalFees));
        } else {
            require(_paymentToSeller + _paymentToBuyer == SafeMath.div(SafeMath.mul(100-thisEscrow.percentUpFront,thisEscrow.price),100));
        }
        require(_amountToSeller + _amountToBuyer == thisEscrow.quantity);
        if(_paymentToSeller > 0){
            thisEscrow.seller.transfer(_paymentToSeller);
        }
        address tokenAddress = thisEscrow.tokenAddress;

        if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC20")){
            if(_amountToSeller > 0){
                Token(tokenAddress).transfer(thisEscrow.seller, _amountToSeller);
            } else if(_amountToBuyer > 0){
                Token(tokenAddress).transfer(thisEscrow.buyer, _amountToBuyer);
            }
        } else if (keccak256(escrowContracts[_index].tokenType) == keccak256("ERC721")){
            if(_amountToSeller == 1){
                ERC721(tokenAddress).transferFrom(thisAddress, escrowContracts[_index].seller, escrowContracts[_index].tokenID);
            } else if(_amountToBuyer == 1){
                ERC721(tokenAddress).transferFrom(thisAddress, escrowContracts[_index].buyer, escrowContracts[_index].tokenID);
            }
        }
        if(_paymentToBuyer > 0){
            thisEscrow.buyer.transfer(_paymentToBuyer);
        }
        emit EscrowArbitrated(thisEscrow.tokenAddress, thisEscrow.tokenID, thisEscrow.arbiter, thisEscrow.seller, thisEscrow.buyer, _amountToSeller, _amountToBuyer, _paymentToSeller, _paymentToBuyer, thisEscrow.percentUpFront, thisEscrow.tokenType, thisEscrow.transType);
        removeEscrow(_index);
        return true;
    }

    /**
    * @dev returns core state of escrow contracts as arrays
    */
    function getEscrowBasic() public view returns (address[], address[], address[], uint256[], uint256[], uint256[]){
        address[] memory sellers= new address[](escrowContracts.length);
        address[] memory buyers= new address[](escrowContracts.length);
        address[] memory arbiters= new address[](escrowContracts.length);
        uint256[] memory prices= new uint256[](escrowContracts.length);
        uint256[] memory amounts= new uint256[](escrowContracts.length);
        uint256[] memory percentsUpFront = new uint256[](escrowContracts.length);
        for (uint i=0; i<escrowContracts.length; i++) {
            //Give contracts that either have buyer/address = msg.sender, or have buyer/address as blank (signaling they are open offers)
            if (msg.sender == escrowContracts[i].seller || msg.sender == escrowContracts[i].buyer || escrowContracts[i].seller == address(0) || escrowContracts[i].buyer == address(0)){
                sellers[i] = escrowContracts[i].seller;
                buyers[i] = escrowContracts[i].buyer;
                arbiters[i] = escrowContracts[i].arbiter;
                prices[i] = escrowContracts[i].price;
                amounts[i] = escrowContracts[i].quantity;
                percentsUpFront[i] = escrowContracts[i].percentUpFront;
            }
        }
        return (sellers, buyers, arbiters, prices, amounts, percentsUpFront);
    }
    
    /**
    * @dev returns token address, ID, and type being traded
    */
    function getEscrowTokenData() public view returns (address[], uint256[], string[], string[]){
        address[] memory tokenAddress = new address[](escrowContracts.length);
        uint256[] memory tokenID = new uint256[](escrowContracts.length);
        string[] memory tokenType = new string[](escrowContracts.length);
        string[] memory saleType = new string[](escrowContracts.length);
        for (uint i=0; i<escrowContracts.length; i++) {
            //Give contracts that either have buyer/address = msg.sender, or have buyer/address as blank (signaling they are open offers)
            if (msg.sender == escrowContracts[i].seller || msg.sender == escrowContracts[i].buyer || escrowContracts[i].seller == address(0) || escrowContracts[i].buyer == address(0)){
                tokenAddress[i] = escrowContracts[i].tokenAddress;
                tokenID[i] = escrowContracts[i].tokenID;
                tokenType[i] = escrowContracts[i].tokenType;
                saleType[i] = escrowContracts[i].transType;
            }
        }
        return (tokenAddress, tokenID, tokenType, saleType);
    }
    
    /**
    * @dev returns fee data for every current Escrow contract
    */
    function getEscrowTaxData() public view returns (string[][], uint256[][], address[][]){
        string[][] memory feeTypes = new string[][](escrowContracts.length);
        uint256[][] memory fees = new uint256[][](escrowContracts.length);
        address[][] memory feeAddresses = new address[][](escrowContracts.length);
        for (uint i=0; i<escrowContracts.length; i++) {
            //Give contracts that either have buyer/address = msg.sender, or have buyer/address as blank (signaling they are open offers)
            if (msg.sender == escrowContracts[i].seller || msg.sender == escrowContracts[i].buyer || escrowContracts[i].seller == address(0) || escrowContracts[i].buyer == address(0)){
                feeTypes[i] = escrowContracts[i].feeTypes;
                fees[i] = escrowContracts[i].fees;
                feeAddresses[i] = escrowContracts[i].feeAddresses;
            }
        }
        return (feeTypes, fees, feeAddresses);
    }

    /**
    * @dev returns escrow buyer signatures.  functions can only handle finite parameters so split getEscrows
    */
    function getBuyerEscrowSignatures() public view returns (bool[], bool[], bool[], bool[]){
        bool[] memory buyerSigned= new bool[](escrowContracts.length);
        bool[] memory buyerUnSigned = new bool[](escrowContracts.length);
        bool[] memory buyerReleased = new bool[](escrowContracts.length);
        bool[] memory buyerDisputed = new bool[](escrowContracts.length);
        for (uint i=0; i<escrowContracts.length; i++) {
            //Give contracts that either have buyer/address = msg.sender, or have buyer/address as blank (signaling they are open offers)
            if (msg.sender == escrowContracts[i].seller || msg.sender == escrowContracts[i].buyer || escrowContracts[i].seller == address(0) || escrowContracts[i].buyer == address(0)){
                buyerSigned[i] = escrowContracts[i].buyerSigned;
                buyerUnSigned[i] = escrowContracts[i].buyerUnSigned;
                buyerReleased[i] = escrowContracts[i].buyerReleased;
                buyerDisputed[i] = escrowContracts[i].buyerDisputed;
            }
        }
        return (buyerSigned, buyerUnSigned, buyerReleased, buyerDisputed);
    }

    /**
    * @dev returns escrow seller signatures.  functions can only handle finite parameters so split getEscrows
    */
    function getSellerEscrowSignatures() public view returns (bool[], bool[], bool[], bool[]){
        bool[] memory sellerSigned= new bool[](escrowContracts.length);
        bool[] memory sellerUnSigned = new bool[](escrowContracts.length);
        bool[] memory sellerReleased = new bool[](escrowContracts.length);
        bool[] memory sellerDisputed = new bool[](escrowContracts.length);
        for (uint i=0; i<escrowContracts.length; i++) {
            //Give contracts that either have buyer/address = msg.sender, or have buyer/address as blank (signaling they are open offers)
            if (msg.sender == escrowContracts[i].seller || msg.sender == escrowContracts[i].buyer || escrowContracts[i].seller == address(0) || escrowContracts[i].buyer == address(0)){
                sellerSigned[i] = escrowContracts[i].sellerSigned;
                sellerUnSigned[i] = escrowContracts[i].sellerUnSigned;
                sellerReleased[i] = escrowContracts[i].sellerReleased;
                sellerDisputed[i] = escrowContracts[i].sellerDisputed;
            }
        }
        return (sellerSigned, sellerUnSigned, sellerReleased, sellerDisputed);
    }

    /**
    * @dev removes escrow contract
    * @param _index the index/ID of the escrow contract
    */
    function removeEscrow(uint _index) internal {
        require(_index < escrowContracts.length);
        if (_index >= escrowContracts.length) return;
        for (uint i = _index; i<escrowContracts.length-1; i++){
            escrowContracts[i] = escrowContracts[i+1];
        }
        delete escrowContracts[escrowContracts.length-1];
        escrowContracts.length--;
    }
    
    function getFeeTotal(uint _index) internal returns (uint256){
        require(_index < escrowContracts.length);
        uint256 feeTotal = 0;
        for (uint i = 0 ; i < escrowContracts[_index].fees.length; i++){
            feeTotal = SafeMath.add(feeTotal, escrowContracts[_index].fees[i]);
        }
        return feeTotal;
    }
    
    function getFees(uint _index) internal returns (uint256[]){
        require(_index < escrowContracts.length);
        uint256[] fees;
        for (uint i = 0 ; i < escrowContracts[_index].fees.length; i++){
            fees.push(escrowContracts[_index].fees[i]);
        }
        return fees;
    }
    
    /**
    * Event for recording escrowSigning
    * @param _escrowIndex the index/ID of the escrow contract
    * @param _signer the address signing
    */
    event EscrowSigned(uint256 _escrowIndex, address _signer);
    
    /**
    * Event for recording completion of transaction
    * @param _tokenAddress token contract address
    * @param _seller address of seller leave blank to allow anyone to sign as seller
    * @param _buyer address of buyer leave blank to allow anyone to sign as buyer
    * @param _price total cost of the deal
    * @param _amount total ownership tokens of the deal
    * @param _percentUpFront percent of total cost to be paid to seller once both parties sign
    * @param _transType the type/purpose of transaction ('resale' or 'consumption')
    * @param _feeTypes description of the tax
    * @param _fees tax payment in ether
    * @param _feeAddresses tax collection address
    */
    event EscrowFinalized(address _tokenAddress, uint256 _tokenID, address _seller, address _buyer, uint256 _price, uint256 _amount, uint256 _percentUpFront, string _transType, string[] _feeTypes, uint256[] _fees, address[] _feeAddresses, string tokenType);

    /**
    * Event for recording arbitration of a contract
    * @param _tokenAddress Address of token contract
    * @param _arbiter Address of arbiter
    * @param _seller address of seller
    * @param _buyer address of buyer
    * @param _amountToSeller Amount of ownership tokens to give seller
    * @param _amountToBuyer Amount of ownership tokens to give buyer
    * @param _paymentToSeller funds to give seller
    * @param _paymentToBuyer funds to give buyer
    * @param _percentUpFront up front payment percentage given when both parties sign
    * @param _tokenType //ERC20, ERC721 etc
    * @param _transType the type/purpose of transaction ('resale' or 'consumption')
    */
    event EscrowArbitrated(address _tokenAddress, uint256 _tokenID, address _arbiter, address _seller, address _buyer, uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer, uint256 _percentUpFront, string _tokenType, string _transType);
}
