pragma solidity ^0.5.0;

import "./Auctionable.sol";
import "./lib/Destructible.sol";
import "./lib/Pausable.sol";
import "./lib/Ownable.sol";

/** @author Shubham Suyal
  * @title Online Marketplace
  */
contract Marketplace is Ownable, Destructible, Pausable, Auctionable {

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

    address[] public admins;
    address[] public storeOwners;
    bytes32[] public stores;

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

    /** @dev Fallback function to save ethers sent by mistake to the contract.
      */
    function() external payable {}

    /** @dev Adds new admin to the system.
      * @param _admin Address of new admin.
      */
    function addAdmin (
        address _admin
    )
        public
        onlyOwner
        newAdmin(_admin)
        whenNotPaused
    {
        admin[_admin] = true;
        admins.push(_admin);
        emit LogNewAdminAdded(_admin);
    }

    /** @dev Removes a present admin from the system.
      * @param _admin Address of new admin.
      */
    function removeAdmin(address _admin) public onlyOwner whenNotPaused {
        admin[_admin] = false;
        removeAdminFromAdminList(_admin);
        emit LogAdminRemoved(_admin);
    }

    /** @dev Adds a new store owner to the system.
      * @param _newStoreOwner Address of the new store owner.
      */
    function addStoreOwner(address _newStoreOwner)
        public
        onlyAdmin
        newStoreOwner(_newStoreOwner)
        whenNotPaused
    {
        storeOwner[_newStoreOwner] = true;
        storeOwners.push(_newStoreOwner);
        emit LogNewStoreOwnerAdded(_newStoreOwner, msg.sender);
    }

    /** @dev Removes store owner from the system.
      * @param _storeOwner Address of the store owner.
      */
    function removeStoreOwner(address _storeOwner)
        public
        onlyAdmin
        whenNotPaused
    {
        storeOwner[_storeOwner] = false;
        removeStoreOwnerFromStoreOwnerList(_storeOwner);
        emit LogStoreOwnerRemoved(_storeOwner);
    }

    /** @dev Adds new store to the marketplace.
      * @param _storeId Id of the new store.
      * @param _name Name of the new store.
      */
    function addStore(bytes32 _storeId, string memory _name)
        public
        onlyStoreOwner
        newStore(_storeId)
        whenNotPaused
    {
        Store memory thisStore;
        thisStore.name = _name;
        thisStore.owner = msg.sender;
        store[_storeId] = thisStore;
        stores.push(_storeId);
        storesOfOwners[msg.sender].push(_storeId);
        emit LogNewStoreAdded(_storeId, msg.sender);
    }

    /** @dev Removes a store from the marketplace.
      * @param _storeId Id of the store.
      */
    function removeStore(bytes32 _storeId)
        public
        onlyStoreOwner
        ownerOfStore(_storeId)
        whenNotPaused
    {
        delete store[_storeId];
        removeStoreFromStoreList(_storeId);
        removeStoreFromStoresOfOwnersList(_storeId, msg.sender);
        emit LogStoreRemoved(_storeId, msg.sender);
    }

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

    /** @dev Withdraws funds of store owner.
      * @param amount Amount of fund to withdraw.
      */
    function withdrawFunds(uint amount)
        public
        onlyStoreOwner
        validWithdrawValue(amount)
        sufficientBalance(amount)
    {
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
        emit LogFundsWithdrawn(msg.sender, amount);
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

    /** @dev Gets the type of user calling this function.
      * @return UserType Type of user.
      */
    function getUserType () public view returns (UserType) {
        if (admin[msg.sender] == true) return UserType .ADMIN;
        else if (storeOwner[msg.sender] == true) return UserType .SHOP_OWNER;
        else return UserType .CUSTOMER;
    }

    /** @dev Gets details of a particular product.
      * @param _productId Id of the product.
      * @return _product.name Name of the product.
      * @return _product.quantity Quantity of the product.
      * @return _product.value Value of the product
      * @return _product.storeId Id of the store the product belongs to.
      */
    function getProductDetails(bytes32 _productId) public view returns (
        string memory,
        uint,
        uint,
        bytes32
    )
    {
        Product memory _product = product[_productId];
        return (_product.name, _product.quantity,
            _product.value, _product.storeId);
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

    /** @dev Removes a particular admin from the list of admins.
      * @param _admin Address of the admin.
      */
    function removeAdminFromAdminList(
        address _admin
    )
        internal
    {
        if (admins[admins.length - 1] == _admin) {
            admins.length--;
            return;
        }
        for(uint i = 0; i < admins.length - 1; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[admins.length - 1];
                admins.length--;
                return;
            }
        }
        revert("admin not found");
    }

    /** @dev Removes a particular store owner from the list of store owners.
      * @param _storeOwner Address of the store owner.
      */
    function removeStoreOwnerFromStoreOwnerList(
        address _storeOwner
    )
        internal
    {
        if (storeOwners[storeOwners.length - 1] == _storeOwner) {
            storeOwners.length--;
            return;
        }
        for(uint i = 0; i < storeOwners.length - 1; i++) {
            if (storeOwners[i] == _storeOwner) {
                storeOwners[i] = storeOwners[storeOwners.length - 1];
                storeOwners.length--;
                return;
            }
        }
        revert("store owner not found");
    }

    /** @dev Removes a particular store from the list of stores.
      * @param _storeId Id of the store.
      */
    function removeStoreFromStoreList(
        bytes32 _storeId
    )
        internal
    {
        if (stores[stores.length - 1] == _storeId) {
            stores.length--;
            return;
        }
        for(uint i = 0; i < stores.length - 1; i++) {
            if (stores[i] == _storeId) {
                stores[i] = stores[stores.length - 1];
                stores.length--;
                return;
            }
        }
        revert("store not found");
    }

    /** @dev Removes a particular store from the list of stores.
      * @param _storeId Id of the store.
      * @param _storeOwner Id of the store.
      */
    function removeStoreFromStoresOfOwnersList(
        bytes32 _storeId,
        address _storeOwner
    )
        internal
    {
        bytes32[] memory stores_ = storesOfOwners[_storeOwner];
        if (stores_[stores_.length - 1] == _storeId) {
                storesOfOwners[_storeOwner].length--;
                return;
        }
        for(uint i = 0; i < stores_.length - 1; i++) {
            if (stores_[i] == _storeId) {
                stores_[i] = stores_[stores_.length - 1];
                storesOfOwners[_storeOwner].length--;
                return;
            }
        }
        revert("store not found");
    }

}