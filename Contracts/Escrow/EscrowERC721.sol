pragma solidity ^0.5.00;
import "../SafeMath.sol";
import "../NonFungible/ERC721.sol"; 
import "../Fungible/Token.sol";
pragma experimental ABIEncoderV2;

contract EscrowERC721{
    address tokenAddress;
    uint256 tokenID;
    bool buyerSigned;
    bool sellerSigned;
    bool buyerUnSigned;
    bool sellerUnSigned;
    bool buyerReleased;
    bool sellerReleased;
    address payable seller;
    address payable buyer;
    address arbiter;
    uint256 price;
    uint256 percentUpFront;
    string transType; //transaction type ex: 'resale' or 'consumption'
    string[] feeTypes;
    uint256[] fees;
    address[] feeAddresses;
    address[] feeCreditAddresses;
    bool buyerDisputed;
    bool sellerDisputed;
    uint256 totalEscrowEther;

    function getTokenAddress() public view returns (address){return tokenAddress;}
    function getTokenID() public view returns (uint256){ return tokenID;}
    function getBuyerSigned() public view returns (bool){ return buyerSigned;}
    function getSellerSigned() public view returns (bool){ return sellerSigned;}
    function getBuyerUnSigned() public view returns (bool){ return buyerUnSigned;}
    function getSellerUnSigned() public view returns (bool){ return sellerUnSigned;}
    function getBuyerReleased() public view returns (bool){ return buyerReleased;}
    function getSellerReleased() public view returns (bool){ return sellerReleased;}
    function getBuyer() public view returns (address){ return buyer;}
    function getSeller() public view returns (address){ return seller;}
    function getArbiter() public view returns (address){ return arbiter;}
    function getPrice() public view returns (uint256){ return price;}
    function getPercentUpFront() public view returns (uint256){ return percentUpFront;}
    function getTransType() public view returns (string memory){ return transType;}
    function getfeeTypes() public view returns (string[] memory){ return feeTypes;}
    function getfees() public view returns (uint256[] memory){ return fees;}
    function getfeeAddresses() public view returns (address[] memory){ return feeAddresses;}
    function getfeeCreditAddresses() public view returns (address[] memory){ return feeCreditAddresses;}
    function getBuyerDisputed() public view returns (bool){ return buyerDisputed;}
    function getSellerDisputed() public view returns (bool){ return sellerDisputed;}


    /**
    * @dev Constructor, sets the parameters of the escrow contract
    * @param _addresses [original caller, token address, buyer, seller, arbiter, fee addresses..]
    * @param _tokenID identifier of non-fungible token
    * @param _price total price
    * @param _percentUpFront percent of price paid to seller once both parties sign
    * @param _release allows original caller to release up front
    * @param _transType type of transaction ex: "resale", "consumption", "import" 
    * @param _feeTypes types of fees included, corresponding to fees. ex: [carbon tax, sales tax, ..]
    * @param _fees fees included ex: [10, 100, ..]
    * @param _feeCreditAddresses addresses of credits to use to offset fees (ex using carbon credits to offset carbon tax)
    */    
    constructor(address[] memory _addresses, uint256 _tokenID, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees, address[] memory _feeCreditAddresses) public payable {
        require(0 <= _percentUpFront && _percentUpFront <= 100);
        require(_fees.length == _feeTypes.length && _fees.length == _feeCreditAddresses.length);
        tokenAddress = _addresses[1];
        tokenID = _tokenID;
        ERC721 tokenInstance = ERC721(tokenAddress);
        seller = address(uint160(_addresses[3]));
        buyer = address(uint160(_addresses[2]));
        arbiter = _addresses[4];
        price = _price;
        percentUpFront = _percentUpFront;
        transType = _transType;
        for(uint a = 5; a < _addresses.length; a++){
            feeAddresses.push(_addresses[a]);
        }
        feeCreditAddresses = _feeCreditAddresses;
        feeTypes = _feeTypes;
        fees = _fees;

        //if sender is seller
        if(_addresses[0] == _addresses[3]){
            require(tokenInstance.getApproved(_tokenID) == address(this));
            tokenInstance.transferFrom(_addresses[2], address(this), _tokenID);
            sellerSigned = true;
            sellerReleased = _release;
        } else {
            require(_addresses[0] == _addresses[2]);
            uint256 totalFees = 0;
            for(uint i = 0; i < _fees.length; i++){
                totalFees = SafeMath.add(totalFees, _fees[i]);
            }
            //use credits to offset fees
            for(uint j = 0; j < _feeCreditAddresses.length; j++){
                if(address(_feeCreditAddresses[j]) != address(0)){
                    if(Token(_feeCreditAddresses[j]).allowance(msg.sender, address(this)) == _fees[j]){
                        Token(_feeCreditAddresses[j]).transferFrom(msg.sender, address(this), _fees[j]);
                        totalFees = SafeMath.sub(totalFees, _fees[j]);   
                    }
                }
            }
            require(msg.value == SafeMath.add(_price,totalFees));
            totalEscrowEther = SafeMath.add(_price,totalFees);
            buyerSigned = true;
            buyerReleased = _release;
        }
    }

    function signEscrow() public payable returns (bool){
        if((buyer == msg.sender || buyer == address(0)) && buyerSigned == false){
            uint256 totalFees = 0;
            for(uint j = 0; j < fees.length; j++){
                if(address(feeCreditAddresses[j]) != address(0)){  //use credits to offset fees
                    if(Token(feeCreditAddresses[j]).allowance(msg.sender, address(this)) == fees[j]){
                        Token(feeCreditAddresses[j]).transferFrom(msg.sender, address(this), fees[j]);
                        totalFees = SafeMath.sub(totalFees, fees[j]);   
                    }
                } else {
                    totalFees = SafeMath.add(totalFees, fees[j]);
                }
            }
            require(msg.value == SafeMath.add(price, totalFees));
            buyer = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            buyerSigned = true;
            return true;
        } else if((seller == msg.sender || seller == address(0)) && sellerSigned == false){
            require(msg.value == 0);
            require(ERC721(tokenAddress).getApproved(tokenID) == address(this));
            ERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenID);
            seller = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            sellerSigned = true;
            return true;
        }
        else return false;
    }

    /**
    * @dev Allows the buyer and seller to unsign a contract, it also automatically deletes the contract once both have unsigned
    * this allows buyer and seller to delete the contract without arbitration
    */
    function unSignEscrow() public returns (bool){
        require(buyer == msg.sender || seller == msg.sender);
        uint256 totalFees;
        for(uint m = 0; m < fees.length; m++){
            totalFees = SafeMath.add(totalFees, fees[m]);
        }
        if(buyer == msg.sender && buyerSigned == true){
            buyerUnSigned = true;
            if (buyerSigned == false){
                //seller never signed, can refund buyer his money (minus percent paid up front) and delete the contract
                //If tax was put in escrow up front, refund the tax as well
                //refund credits
                for(uint j = 0; j < fees.length; j++){
                    if(address(feeCreditAddresses[j]) != address(0)){
                        if(Token(feeCreditAddresses[j]).balanceOf(address(this)) >= fees[j]){
                            Token(feeCreditAddresses[j]).transfer(buyer, fees[j]);
                            totalFees = SafeMath.sub(totalFees, fees[j]);   
                        }
                    }
                }
                buyer.transfer(SafeMath.add(totalFees, SafeMath.div(SafeMath.mul(100-percentUpFront,price),100)));
                selfdestruct(msg.sender);
                return true;
            }
        } else if (seller == msg.sender && sellerSigned == true){
            sellerUnSigned = true;
            if (buyerSigned == false){
                //buyer never signed, can refund seller his shares and delete the contract
                ERC721(tokenAddress).transferFrom(address(this), seller, tokenID);
                selfdestruct(msg.sender);
                return true;
            }
        } else return false;
        if (buyerUnSigned == true && sellerUnSigned == true){
            //both parties have signed but then unsigned, can refund both and delete contract
            ERC721(tokenAddress).transferFrom(address(this), seller, tokenID);
            //Buyer paid percentUpFront when they signed, so remove that from the refund
            //If credits and fees were put in escrow up front, refund those as well
            for(uint j = 0; j < fees.length; j++){
                if(address(feeCreditAddresses[j]) != address(0)){
                    if(Token(feeCreditAddresses[j]).balanceOf(address(this)) >= fees[j]){
                        Token(feeCreditAddresses[j]).transfer(buyer, fees[j]);
                        totalFees = SafeMath.sub(totalFees, fees[j]);   
                    }
                }
            }
            buyer.transfer(SafeMath.add(totalFees,SafeMath.div(SafeMath.mul(100-percentUpFront,price),100)));
            selfdestruct(msg.sender);
        }
        return true;
    }

    /**
    * @dev completes the escrow contract, transfering payment to seller and ownership to buyer, both parties must release
    */
    function releaseEscrow() public returns (bool){
        //if buyer has signed and not unsigned, mark buyerReleased as True
        if((buyer == msg.sender || msg.sender == address(this)) && buyerSigned == true && buyerUnSigned == false){
            buyerReleased = true;
        //if seller has signed and not unsigned, mark sellerReleased as True
        } else if((buyer == msg.sender || msg.sender == address(this)) && sellerSigned == true && sellerUnSigned == false){
            sellerReleased = true;
        }
        if(buyerReleased && sellerReleased){
            require(buyerDisputed == false && sellerDisputed == false);
            ERC721(tokenAddress).transferFrom(address(this), buyer, tokenID);
            //transfer funds to the seller minus how much was paid up front
            seller.transfer(SafeMath.div(SafeMath.mul(100-percentUpFront,price),100));
            //pay fees, which were collected when the buyer signed
            for(uint i = 0; i < fees.length; i++){
                address payable escrowTaxAddress = address(uint160(feeAddresses[i]));
                if(feeCreditAddresses[i] != address(0)){
                    Token(feeCreditAddresses[i]).transfer(escrowTaxAddress, fees[i]);
                } else {
                    escrowTaxAddress.transfer( fees[i] );
                }
            }
            emit EscrowFinalized(tokenAddress, tokenID, seller, buyer, price, percentUpFront, transType, feeTypes, fees, feeAddresses);
            selfdestruct(msg.sender);
        }
        return true;
    }

    /**
    * @dev Allows buyer and seller to unRelease Escrow
    */
    function unReleaseEscrow() public returns (bool){
        if(buyer == msg.sender && buyerReleased == true){
            buyerReleased = false;
        } else if(seller == msg.sender && sellerReleased == true){
            sellerReleased = false;
        }
        return true;
    }

    /**
    * @dev Allows an address to sign and finalize escrow in the same transaction
    */
    function signAndReleaseEscrow() public payable returns (bool){
        if((buyer == msg.sender || buyer == address(0)) && buyerSigned == false){
            uint256 totalFees = 0;
            for(uint j = 0; j < fees.length; j++){
                if(address(feeCreditAddresses[j]) != address(0)){  //use credits to offset fees
                    if(Token(feeCreditAddresses[j]).allowance(msg.sender, address(this)) == fees[j]){
                        Token(feeCreditAddresses[j]).transferFrom(msg.sender, address(this), fees[j]);
                        totalFees = SafeMath.sub(totalFees, fees[j]);   
                    }
                } else {
                    totalFees = SafeMath.add(totalFees, fees[j]);
                }
            }
            require(msg.value == SafeMath.add(price, totalFees));
            buyer = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            buyerSigned = true;
        } else if((seller == msg.sender || seller == address(0)) && sellerSigned == false){
            require(msg.value == 0);
            require(ERC721(tokenAddress).getApproved(tokenID) == address(this));
            ERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenID);
            seller = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            sellerSigned = true;
        } else return false;

        //Finalize escrow
        if(buyer == msg.sender){
            buyerReleased = true;
        //if seller has signed and not unsigned, mark sellerReleased as True
        } else if(buyer == msg.sender){
            sellerReleased = true;
        } else return false;
        releaseEscrow();
    }

    function getFeeTotal() internal returns (uint256){
        uint256 feeTotal = 0;
        for (uint i = 0 ; i < fees.length; i++){
            feeTotal = SafeMath.add(feeTotal, fees[i]);
        }
        return feeTotal;
    }

    /**
    * @dev Buyer or Seller can dispute an escrow contract if they have signed
    */
    function disputeEscrow(uint256 _index) public returns (bool){
        //only buyer or seller can dispute a contract, and onyl if they have signed it
        if(buyer == msg.sender){
            require(buyerSigned == true);
            require(buyerDisputed == false);
            buyerDisputed = true;
        } else if (seller == msg.sender){
            require(sellerSigned == true);
            require(sellerDisputed == false);
            sellerDisputed = true;
        } else return false;
        return true;
    }

    /**
    * @dev Buyer or Seller can unDispute an escrow contract if they have disputed
    */
    function unDisputeEscrow() public returns (bool){
        //only buyer or seller can dispute a contract, and onyl if they have signed it
        if(buyer == msg.sender){
            require(buyerDisputed == true);
            buyerDisputed = false;
        } else if (seller == msg.sender){
            require(sellerDisputed == true);
            sellerDisputed = false;
        } else return false;
        return true;
    }

    // For ERC721, amountToBuyer and amountToSeller should be 1 and 0 or vice versa, since it is one unique item
    /**
    * @dev Arbiter can arbitrate an escrow contract, divying up the ownership tokens and funds held in the escrow contract between buyer and seller
    * @param _amountToSeller Amount of ownership tokens to give seller
    * @param _amountToBuyer Amount of ownership tokens to give buyer
    * @param _paymentToSeller funds to give seller
    * @param _paymentToBuyer funds to give seller
    * @param _feesToBuyer the fees which will be refunded to Buyer
    */
    function arbitrateEscrow(uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer, uint256[] memory _feesToBuyer) public returns (bool){
        require(msg.sender == arbiter);
        require(buyerDisputed == true || sellerDisputed == true);
        ERC721 tokenInstance = ERC721(tokenAddress);
        if(buyerDisputed == false){
            require(msg.sender != seller);
        } else if (sellerDisputed == false){
            require(msg.sender != buyer);
        }
        require(buyerSigned == true && sellerSigned == true);
        require(fees.length == feeCreditAddresses.length);
        uint256 totalPaymentToBuyer = _paymentToBuyer;
        for(uint i = 0; i < fees.length; i++){
            if(_feesToBuyer[i] == fees[i]){ //this fee should be refunded to buyer 
                if(address(feeCreditAddresses[i]) != address(0)){ //refund credit
                    Token(feeCreditAddresses[i]).transfer(buyer, fees[i]);
                } else { //fee is denominated in Ether and is intended to be refunded to buyer, add to totalFeesToBuyer
                    totalPaymentToBuyer = SafeMath.add(totalPaymentToBuyer, fees[i]); 
                }
            } else { //give fee to fee collector
                if(address(feeCreditAddresses[i]) != address(0)){ //refund credit
                    Token(feeCreditAddresses[i]).transfer(feeCreditAddresses[i], fees[i]);
                } else {
                    address payable escrowTaxAddress = address(uint160(feeAddresses[i]));
                    escrowTaxAddress.transfer(fees[i]);
                }
            }
        }
        require(_paymentToSeller + totalPaymentToBuyer == totalEscrowEther);
        require(_amountToSeller + _amountToBuyer == 1);
        if(_paymentToSeller > 0){
            seller.transfer(_paymentToSeller);
        }
        if(_amountToSeller == 1 && _amountToBuyer == 0){
            tokenInstance.transferFrom(address(this), seller, tokenID);
        } else if(_amountToSeller == 0 && _amountToBuyer == 1){
            tokenInstance.transferFrom(address(this), buyer, tokenID);
        }
        if(totalPaymentToBuyer > 0){
            buyer.transfer(totalPaymentToBuyer);
        }
        emit EscrowArbitrated(tokenAddress, tokenID, arbiter, seller, buyer, _amountToSeller, _amountToBuyer, _paymentToSeller, _paymentToBuyer, percentUpFront, transType);
        selfdestruct(msg.sender);
        return true;
    }

    /**
    * Event for recording completion of transaction
    * @param _tokenAddress token contract address
    * @param _tokenID identifier of non-fungible token
    * @param _seller address of seller leave blank to allow anyone to sign as seller
    * @param _buyer address of buyer leave blank to allow anyone to sign as buyer
    * @param _price total cost of the deal
    * @param _percentUpFront percent of total cost to be paid to seller once both parties sign
    * @param _transType the type/purpose of transaction ('resale' or 'consumption')
    * @param _feeTypes description of the tax
    * @param _fees tax payment in ether
    * @param _feeAddresses tax collection address
    */
    event EscrowFinalized(address _tokenAddress, uint256 _tokenID, address _seller, address _buyer, uint256 _price, uint256 _percentUpFront, string _transType, string[] _feeTypes, uint256[] _fees, address[] _feeAddresses);

    /**
    * Event for recording arbitration of a contract
    * @param _tokenAddress Address of token contract
    * @param _tokenID identifier of non-fungible token
    * @param _arbiter Address of arbiter
    * @param _seller address of seller
    * @param _buyer address of buyer
    * @param _amountToSeller Amount of ownership tokens to give seller
    * @param _amountToBuyer Amount of ownership tokens to give buyer
    * @param _paymentToSeller funds to give seller
    * @param _paymentToBuyer funds to give buyer
    * @param _percentUpFront up front payment percentage given when both parties sign
    * @param _transType the type/purpose of transaction ('resale' or 'consumption')
    */
    event EscrowArbitrated(address _tokenAddress, uint256 _tokenID, address _arbiter, address _seller, address _buyer, uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer, uint256 _percentUpFront, string _transType);
}


    
    
