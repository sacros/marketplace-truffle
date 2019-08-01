pragma solidity ^0.5.0;
import "./lib/Pausable.sol";
import "./Auctionable.sol";

/** @author Shubham Suyal
  * @title StoreProducts
  */
contract StoreProducts is Pausable, Auctionable {
    enum UserType  {OWNER, ADMIN, SHOP_OWNER, CUSTOMER}

    struct Product {
        string name;
        uint quantity;
        uint value;
        bytes32 storeId;
    }

    mapping(address => bool) public admin;
    mapping(address => bytes32[]) public storesOfOwners;
    mapping(bytes32 => Product) public product;
    mapping(bytes32 => bytes32[]) public productsOfStore;

    modifier onlyAdmin {
        require(admin[msg.sender] == true, "user not an admin.");
        _;
    }

    modifier newAdmin(address _admin) {
        require(admin[_admin] == false, "admin already present");
        _;
    }

    modifier newStoreOwner(address _storeOwner) {
        require(storeOwner[_storeOwner] == false,
            "store owner already present");
        _;
    }

    modifier newStore(bytes32 storeId) {
        require(bytes(store[storeId].name).length == 0,
            "store with this storeId already exists.");
        _;
    }

    modifier newProduct(bytes32 productId) {
        require(bytes(product[productId].name).length == 0,
            "product with this productId already exists.");
        _;
    }

    modifier alreadyPresentProduct(bytes32 productId) {
        require(bytes(product[productId].name).length != 0,
            "product with this productId doesn't exists.");
        _;
    }

    modifier storeOfProduct(bytes32 _storeId, bytes32 _productId) {
        require(product[_productId].storeId == _storeId,
            "product doesn't belong to this store.");
        _;
    }

    modifier sufficientFundsAndStocks(bytes32 _productId, uint _quantity) {
        require(product[_productId].quantity >= _quantity,
            "insufficient stocks.");
        require(product[_productId].value * _quantity <= msg.value,
            "insufficient funds.");
        _;
        uint refundAmount = msg.value -
            (product[_productId].value * _quantity);
        msg.sender.transfer(refundAmount);
    }

    modifier sufficientBalance(uint _amount) {
        require(balances[msg.sender] >= _amount, "insufficient balance.");
        _;
    }

    modifier storeExists(bytes32 _storeId) {
        require(bytes(store[_storeId].name).length != 0,
            "store doesn't exist.");
        _;
    }

    modifier productExists(bytes32 _productId) {
        require(bytes(product[_productId].name).length != 0,
            "product doesn't exist.");
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
    event LogNewAdminAdded(address indexed admin);
    event LogAdminRemoved(address indexed admin);
    event LogNewStoreOwnerAdded(
        address indexed storeOwner,
        address indexed admin
    );
    event LogStoreOwnerRemoved(address indexed storeOwner);
    event LogNewStoreAdded(
        bytes32 indexed storeId,
        address indexed storeOwner
    );
    event LogStoreRemoved(
        bytes32 indexed storeId,
        address indexed storeOwner
    );
    event LogNewProductAdded(
        bytes32 indexed storeId,
        bytes32 indexed productId,
        address indexed storeOwner
    );
    event LogProductDetailsChanged(
        bytes32 indexed storeId,
        bytes32 indexed productId,
        string newName,
        uint newQuantity,
        uint newValue
    );
    event LogProductRemoved(
        bytes32 indexed productId,
        bytes32 indexed storeId
    );
    event LogFundsWithdrawn(address indexed storeOwner, uint amount);
    event LogProductBought(address indexed buyer, bytes32 indexed productId);


    address[] public admins;
    address[] public storeOwners;
    bytes32[] public stores;
        /** @dev Adds new product to the store.
      * @param _storeId Id of the store.
      * @param _productId Id of the product.
      * @param _name Name of the product.
      * @param _quantity Quantity of the product.
      * @param _value Value of the product (individual).
      */
    function addProduct(
        bytes32 _storeId,
        bytes32 _productId,
        string memory _name,
        uint _quantity,
        uint _value
    )
        public
        onlyStoreOwner
        ownerOfStore(_storeId)
        newProduct(_productId)
        whenNotPaused
    {
        Product memory thisProduct;
        thisProduct.name = _name;
        thisProduct.quantity = _quantity;
        thisProduct.value = _value;
        thisProduct.storeId = _storeId;
        product[_productId] = thisProduct;
        productsOfStore[_storeId].push(_productId);
        emit LogNewProductAdded(_storeId, _productId, msg.sender);
    }

    /** @dev Edits product details.
      * @param _storeId Id of the store.
      * @param _productId Id of the product.
      * @param _name Name of the product.
      * @param _quantity Quantity of the product.
      * @param _value Value of the product (individual).
      */
    function changeProductDetails(
        bytes32 _storeId,
        bytes32 _productId,
        string memory _name,
        uint _quantity,
        uint _value
    )
        public
        onlyStoreOwner
        ownerOfStore(_storeId)
        storeOfProduct(_storeId, _productId)
        alreadyPresentProduct(_productId)
        whenNotPaused
    {
        product[_productId].name = _name;
        product[_productId].value = _value;
        product[_productId].quantity = _quantity;
        emit LogProductDetailsChanged(
            _storeId,
            _productId,
            _name,
            _quantity,
            _value
        );
    }

    /** @dev Removes product from the marketplace.
      * @param _productId Id of the product.
      */
    function removeProduct(bytes32 _productId)
        public
        onlyStoreOwner
        ownerOfStore(product[_productId].storeId)
        whenNotPaused
    {
        removeProductFromStore(product[_productId].storeId, _productId);
        delete product[_productId];
        emit LogProductRemoved(_productId, product[_productId].storeId);
    }

    /** @dev Buys a product from the marketplace.
      * @param _productId Id of the product.
      * @param _quantity Quantity of the product.
      */
    function buyProduct(bytes32 _productId, uint _quantity)
        public
        payable
        productExists(_productId)
        storeExists(product[_productId].storeId)
        sufficientFundsAndStocks(_productId, _quantity)
        whenNotPaused
    {
        address _storeOwner = store[product[_productId].storeId].owner;
        balances[_storeOwner] += product[_productId].value * _quantity;
        product[_productId].quantity -= _quantity;
        emit LogProductBought(msg.sender, _productId);
    }

        /** @dev Removes a particular product from the list of a store's products.
      * @param _storeId Id of the store.
      * @param _productId Id of the product.
      */
    function removeProductFromStore(
        bytes32 _storeId,
        bytes32 _productId
    )
        internal
    {
        bytes32[] memory products = productsOfStore[_storeId];
        if (products[products.length - 1] == _productId) {
            productsOfStore[_storeId].length--;
            return;
        }
        for(uint i = 0; i < products.length - 1; i++) {
            if (products[i] == _productId) {
                productsOfStore[_storeId][i] = products
                    [products.length - 1];
                productsOfStore[_storeId].length--;
                return;
            }
        }
        revert("product not found.");
    }



}
