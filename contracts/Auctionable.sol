pragma solidity ^0.5.0;

import "./lib/Pausable.sol";

/** @author Shubham Suyal
  * @title Auctionable
  */
contract Auctionable is Pausable {

    enum AuctionProductSatus {ONGOING, ENDED, CANCELED}

    struct AuctionProduct {
        string name;
        bytes32 storeId;
        uint endBlock;
        address buyer;
        uint startBid;
        uint highestBid;
        address highestBidder;
        AuctionProductSatus status;
    }

    struct Store {
        string name;
        address owner;
    }

    mapping(bytes32 => AuctionProduct) public auctionProduct;
    mapping(address => mapping(bytes32 => uint)) userAuctionBid;
    mapping(bytes32 => bytes32[]) public auctionProductsOfStore;
    mapping(address => bool) public storeOwner;
    mapping(bytes32 => Store) public store;
    mapping(address => uint) public balances;

    modifier newAuctionProduct(bytes32 productId) {
        require(bytes(auctionProduct[productId].name).length == 0,
            "auction product with this productId already exists.");
        _;
    }

    modifier auctionAlive(bytes32 _productId) {
        require(auctionProduct[_productId].status ==
            AuctionProductSatus.ONGOING, "auction ended/canceled.");
        require(block.number < auctionProduct[_productId].endBlock,
            "auction not alive.");
        _;
    }

    modifier auctionOngoing(bytes32 _productId) {
        require(auctionProduct[_productId].status ==
            AuctionProductSatus.ONGOING, "auction not ongoing.");
        _;
    }

    modifier auctionNotAlive(bytes32 _productId) {
        require(auctionProduct[_productId].status !=
            AuctionProductSatus.ONGOING, "auction is still alive.");
        _;
    }

    modifier onlyStoreOwner {
        require(storeOwner[msg.sender] == true, "user not a store owner.");
        _;
    }

    modifier ownerOfStore(bytes32 storeId) {
        require(store[storeId].owner == msg.sender,
            "user not the owner of this store.");
        _;
    }

    modifier checkEndBlock(uint _endBlock) {
        require(_endBlock > block.number,
            "end block should be greater than current block.");
        _;
    }

    modifier validBid() {
        require(msg.value > 0, "zero value bid.");
        _;
    }

    modifier validWithdrawValue(uint value) {
        require(value > 0, "zero value withdraw.");
        _;
    }

    event LogNewAuctionProductAdded(
        bytes32 indexed storeId,
        bytes32 indexed productId,
        address indexed storeOwner
    );
    event LogAuctionCanceled(
        bytes32 indexed productId,
        bytes32 indexed storeId
    );
    event LogAuctionEnded(
        bytes32 indexed productId,
        bytes32 indexed storeId,
        address indexed highestBidder
    );
    event LogBidPlaced(address indexed bidder, uint amount);
    event LogAuctionBidWithdrawn(address indexed bidder, uint amount);

    /** @dev Adds new product to the auction.
      * @param _storeId Id of the store.
      * @param _productId Id of the auction product.
      * @param _name Name of the product.
      * @param _endBlock Last block till auction validity.
      * @param _startBid Start Bid amount of auction.
      */
    function addAuctionProduct(
        bytes32 _storeId,
        bytes32 _productId,
        string memory _name,
        uint _endBlock,
        uint _startBid
    )
        public
        onlyStoreOwner
        ownerOfStore(_storeId)
        checkEndBlock(_endBlock)
        newAuctionProduct(_productId)
        whenNotPaused
    {
            AuctionProduct memory thisProduct;
            thisProduct.name = _name;
            thisProduct.endBlock = _endBlock;
            thisProduct.startBid = _startBid;
            thisProduct.storeId = _storeId;
            thisProduct.status = AuctionProductSatus.ONGOING;
            auctionProduct[_productId] = thisProduct;
            auctionProductsOfStore[_storeId].push(_productId);
            emit LogNewAuctionProductAdded(_storeId, _productId, msg.sender);
    }

    /** @dev Cancels an auction.
      * @param _productId ProductId of auction product.
      */
    function cancelAuction(bytes32 _productId)
        public
        onlyStoreOwner
        ownerOfStore(auctionProduct[_productId].storeId)
        auctionOngoing(_productId)
        whenNotPaused
    {
            auctionProduct[_productId].status = AuctionProductSatus.CANCELED;
            emit LogAuctionCanceled(
                _productId,
                auctionProduct[_productId].storeId
            );
    }

    /** @dev Ends an ongoing auction.
      * @param _productId Id of the auction product.
      */
    function endAuction(bytes32 _productId)
        public
        onlyStoreOwner
        ownerOfStore(auctionProduct[_productId].storeId)
        auctionAlive(_productId)
        whenNotPaused
    {
            auctionProduct[_productId].status = AuctionProductSatus.ENDED;
            balances[msg.sender] += auctionProduct[_productId].highestBid;
            userAuctionBid[auctionProduct[_productId].highestBidder]
                [_productId] = 0;
            emit LogAuctionEnded(
                _productId,
                auctionProduct[_productId].storeId,
                auctionProduct[_productId].highestBidder
            );
    }

    /** @dev Places a bid for an auction.
      * @param _productId Id of the auction product.
      */
    function placeBid(bytes32 _productId)
        public
        payable
        auctionAlive(_productId)
        validBid
        whenNotPaused
    {
            userAuctionBid[msg.sender][_productId] += msg.value;
            if (auctionProduct[_productId].highestBid <
                userAuctionBid[msg.sender][_productId] &&
                userAuctionBid[msg.sender][_productId] >=
                auctionProduct[_productId].startBid) {
                    auctionProduct[_productId].highestBid = userAuctionBid
                        [msg.sender][_productId];
                    auctionProduct[_productId].highestBidder = msg.sender;
            }
            emit LogBidPlaced(
                msg.sender,
                userAuctionBid[msg.sender][_productId]
            );
    }
    /** @dev Withdraws auction fund of customer.
      * @param _productId Id of the product.
      */
    function withdrawAuctionBid(bytes32 _productId)
        public
        auctionNotAlive(_productId)
        validWithdrawValue(userAuctionBid[msg.sender][_productId])
    {
            uint amountToTransfer = userAuctionBid[msg.sender][_productId];
            userAuctionBid[msg.sender][_productId] = 0;
            msg.sender.transfer(amountToTransfer);
            emit LogAuctionBidWithdrawn(msg.sender, amountToTransfer);
    }

}