pragma solidity ^0.5.0;

import "./lib/Destructible.sol";
import "./lib/Ownable.sol";
import "./StoreProducts.sol";

/** @author Shubham Suyal
  * @title Online Marketplace
  */
contract Marketplace is Ownable, Destructible, Pausable, StoreProducts {

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

    /** @dev Gets the type of user calling this function.
      * @return UserType Type of user.
      */
    function getUserType () public view returns (UserType) {
        if(msg.sender == owner) return UserType.OWNER;
        else if (admin[msg.sender] == true) return UserType.ADMIN;
        else if (storeOwner[msg.sender] == true) return UserType.SHOP_OWNER;
        else return UserType.CUSTOMER;
    }

    /** @dev Gets the list of admins.
      * @return admins List of admins.
      */
    function getAdmins() public view returns (address[] memory) {
        return admins;
    }

    /** @dev Gets the list of store owners.
      * @return storeOwners List of store owners.
      */
    function getStoreOwners() public view returns (address[] memory) {
        return storeOwners;
    }
    
    /** @dev Gets the list of stores.
      * @return stores List of stores.
      */
    function getStores() public view returns (bytes32[] memory) {
        return stores;
    }

    /** @dev Gets the list of stores' auction products.
      * @param _storeId Id of the store.
      * @return auctionProductsOfStore List of stores' auction products.
      */
    function getAuctionProductsOfStore(bytes32 _storeId) public view returns (bytes32[] memory) {
        return auctionProductsOfStore[_storeId];
    }

    /** @dev Gets the list of stores of a store owner.
      * @param _storeOwner Address of the store owner.
      * @return storesOfOwners List of stores of a store owner.
      */
    function getStoresOfOwners(address _storeOwner) public view returns (bytes32[] memory) {
        return storesOfOwners[_storeOwner];
    }

    /** @dev Gets the list of products of a store.
      * @param _storeId Id of the store.
      * @return productsOfStore List of products of a store.
      */
    function getProductsOfStore(bytes32 _storeId) public view returns (bytes32[] memory) {
        return productsOfStore[_storeId];
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