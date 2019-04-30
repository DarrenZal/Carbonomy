pragma solidity ^0.5.00;
import "../SafeMath.sol";
import "../Fungible/Token.sol";
pragma experimental ABIEncoderV2;

contract EscrowERC20{
    address tokenAddress;
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
    uint256 quantity;
    uint256 percentUpFront;
    string transType; //transaction type ex: 'resale' or 'consumption'
    string[] feeTypes;
    uint256[] fees;
    address[] feeAddresses;
    bool buyerDisputed;
    bool sellerDisputed;

    function getTokenAddress() public view returns (address){return tokenAddress;}
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
    function getQuantity() public view returns (uint256){ return quantity;}
    function getPercentUpFront() public view returns (uint256){ return percentUpFront;}
    function getTransType() public view returns (string memory){ return transType;}
    function getfeeTypes() public view returns (string[] memory){ return feeTypes;}
    function getfees() public view returns (uint256[] memory){ return fees;}
    function getfeeAddresses() public view returns (address[] memory){ return feeAddresses;}
    function getBuyerDisputed() public view returns (bool){ return buyerDisputed;}
    function getSellerDisputed() public view returns (bool){ return sellerDisputed;}


    /**
    * @dev Constructor, sets the parameters of the escrow contract
    * @param _addresses [original caller, token address, buyer, seller, arbiter, fee addresses..]
    * @param _amount quantity being traded
    * @param _price total price
    * @param _percentUpFront percent of price paid to seller once both parties sign
    * @param _release allows original caller to release up front
    * @param _transType type of transaction ex: "resale", "consumption", "import" 
    * @param _feeTypes types of fees included, corresponding to fees. ex: [carbon tax, sales tax, ..]
    * @param _fees fees included ex: [10, 100, ..]
    */    
    constructor(address[] memory _addresses, uint256 _amount, uint256 _price, uint256 _percentUpFront, bool _release, string memory _transType, string[] memory _feeTypes, uint256[] memory _fees) public payable {
        require(0 <= _percentUpFront && _percentUpFront <= 100);
        tokenAddress = _addresses[1];
        Token tokenInstance = Token(tokenAddress);
        seller = address(uint160(_addresses[3]));
        buyer = address(uint160(_addresses[2]));
        arbiter = _addresses[4];
        price = _price;
        quantity = _amount;
        percentUpFront = _percentUpFront;
        transType = _transType;
        for(uint a = 5; a < _addresses.length; a++){
            feeAddresses.push(_addresses[a]);
        }
        feeTypes = _feeTypes;
        fees = _fees;

        //if sender is seller
        if(_addresses[0] == _addresses[3]){
            require(tokenInstance.allowance( _addresses[3],  address(this)) >= _amount);
            require(tokenInstance.balanceOf(_addresses[3]) >= _amount);
            tokenInstance.transferFrom(_addresses[3], address(this), _amount);
            sellerSigned = true;
            sellerReleased = _release;
        } else {
            require(_addresses[0] == _addresses[2]);
            uint256 totalFees = 0;
            for(uint i = 0; i < _fees.length; i++){
                totalFees = SafeMath.add(totalFees, _fees[i]);
            }
            require(msg.value == SafeMath.add(_price,totalFees));
            buyerSigned = true;
            buyerReleased = _release;
        }
    }

    function signEscrow() public payable returns (bool){
        if((buyer == msg.sender || buyer == address(0)) && buyerSigned == false){
            if(fees.length > 0){
                uint256 totalFees = 0;
                for(uint l = 0; l < fees.length; l++){
                    totalFees = SafeMath.add(totalFees, fees[l]);
                }
                require(msg.value == SafeMath.add(price, totalFees));
            } else {
                require(msg.value == price);
            }
            buyer = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            buyerSigned = true;
            return true;
        } else if((seller == msg.sender || seller == address(0)) && sellerSigned == false){
            require(msg.value == 0);
            require(quantity <= Token(tokenAddress).balanceOf(msg.sender));
            require(Token(tokenAddress).allowance( msg.sender,  address(this)) >= quantity);
            Token(tokenAddress).transferFrom(msg.sender, address(this), quantity);
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
                if(fees.length > 0){
                    buyer.transfer(SafeMath.add(totalFees, SafeMath.div(SafeMath.mul(100-percentUpFront,price),100)));
                } else {
                    buyer.transfer(SafeMath.div(SafeMath.mul(100-percentUpFront,price),100));
                }
                selfdestruct(msg.sender);
                return true;
            }
        } else if (seller == msg.sender && sellerSigned == true){
            sellerUnSigned = true;
            if (buyerSigned == false){
                //buyer never signed, can refund seller his shares and delete the contract
                    Token(tokenAddress).transfer(seller, quantity);
                selfdestruct(msg.sender);
                return true;
            }
        } else return false;
        if (buyerUnSigned == true && sellerUnSigned == true){
            //both parties have signed but then unsigned, can refund both and delete contract
            Token(tokenAddress).transfer(seller, quantity);
            //Buyer paid percentUpFront when they signed, so remove that from the refund
            //If tax was put in escrow up front, refund the tax as well
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
                 Token(tokenAddress).transfer(buyer, quantity);
            //transfer funds to the seller minus how much was paid up front
            seller.transfer(SafeMath.div(SafeMath.mul(100-percentUpFront,price),100));
            //pay fees, which were collected when the buyer signed
            if(fees.length > 0){
                for(uint i = 0; i < fees.length; i++){
                    address payable escrowTaxAddress = address(uint160(feeAddresses[i]));
                    escrowTaxAddress.transfer( fees[i] );
                }
            }
            emit EscrowFinalized(tokenAddress, seller, buyer, price, quantity, percentUpFront, transType, feeTypes, fees, feeAddresses);
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
            if(fees.length > 0){
                require(msg.value == SafeMath.add(price, getFeeTotal()));
            } else {
                require(msg.value == price);
            }
            buyer = msg.sender;
            if(percentUpFront > 0 ){
                seller.transfer(SafeMath.div(SafeMath.mul(percentUpFront,price),100));
            }
            buyerSigned = true;
        } else if((seller == msg.sender || seller == address(0)) && sellerSigned == false){
            require(msg.value == 0);
                 require(quantity <= Token(tokenAddress).balanceOf(msg.sender));
                 Token thisToken = Token(tokenAddress);
                 require(thisToken.allowance( msg.sender,  address(this)) >= quantity);
                 thisToken.transferFrom(msg.sender, address(this), quantity);
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
    */
    function arbitrateEscrow(uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer) public returns (bool){
        require(msg.sender == arbiter);
        require(buyerDisputed == true || sellerDisputed == true);
        if(buyerDisputed == false){
            require(msg.sender != seller);
        } else if (sellerDisputed == false){
            require(msg.sender != buyer);
        }
        require(buyerSigned == true && sellerSigned == true);
        if(fees.length > 0){
            uint256 totalFees = 0;
            for(uint i = 0; i < fees.length; i++){
                totalFees = SafeMath.add(totalFees, fees[i]);
            }
            require(_paymentToSeller + _paymentToBuyer == SafeMath.add(SafeMath.div(SafeMath.mul(100-percentUpFront,price),100),totalFees));
        } else {
            require(_paymentToSeller + _paymentToBuyer == SafeMath.div(SafeMath.mul(100-percentUpFront,price),100));
        }
        require(_amountToSeller + _amountToBuyer == quantity);
        if(_paymentToSeller > 0){
            seller.transfer(_paymentToSeller);
        }
            if(_amountToSeller > 0){
                Token(tokenAddress).transfer(seller, _amountToSeller);
            } else if(_amountToBuyer > 0){
                Token(tokenAddress).transfer(buyer, _amountToBuyer);
            }
        if(_paymentToBuyer > 0){
            buyer.transfer(_paymentToBuyer);
        }
        emit EscrowArbitrated(tokenAddress, arbiter, seller, buyer, _amountToSeller, _amountToBuyer, _paymentToSeller, _paymentToBuyer, percentUpFront, transType);
        selfdestruct(msg.sender);
        return true;
    }

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
    event EscrowFinalized(address _tokenAddress, address _seller, address _buyer, uint256 _price, uint256 _amount, uint256 _percentUpFront, string _transType, string[] _feeTypes, uint256[] _fees, address[] _feeAddresses);

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
    * @param _transType the type/purpose of transaction ('resale' or 'consumption')
    */
    event EscrowArbitrated(address _tokenAddress, address _arbiter, address _seller, address _buyer, uint256 _amountToSeller, uint256 _amountToBuyer, uint256 _paymentToSeller, uint256 _paymentToBuyer, uint256 _percentUpFront, string _transType);
}

