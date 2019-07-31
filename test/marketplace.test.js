let Marketplace = artifacts.require('Marketplace')
let Auctionable = artifacts.require('Auctionable')
let catchRevert = require("./exceptionsHelpers.js").catchRevert

contract('Marketplace', (accounts) => {
    const owner = accounts[0]
    const admin = accounts[1]
    const storeOwner = accounts[2]
    const customer = accounts[3]
    
    const storeId = "0x0100000000000000000000000000000000000000000000000000000000000000";
    const storeName = "test-store"

    const productId = "0x0200000000000000000000000000000000000000000000000000000000000000"
    const productName = "test-product"
    const quantity = 10
    const value = 1

    const buyQuantity = 1
    let instance

    beforeEach(async () => {
        instance = await Marketplace.new()
    })


    it('Owner should be able to add an admin', async () => {
        const admin_before = await instance.admin(admin, { from: owner })
        await instance.addAdmin(admin, { from: owner })
        const admin_after = await instance.admin(admin, { from: owner })
        const admins = await instance.admins(0, { from: owner })
        assert.equal(admin_before, false, "Admin should not be added yet.")
        assert.equal(admin_after, true, "Admin should now be added.")
        assert.equal(admins, admin, "Admin not matched")
    })

    it('Admin should be able to add a store owner', async () => {
        const store_owner_before = await instance.storeOwner(storeOwner, { from: admin })
        await instance.addAdmin(admin, { from: owner })
        await instance.addStoreOwner(storeOwner, { from: admin })
        const store_owner_after = await instance.storeOwner(storeOwner, { from: admin })
        const storeOwners = await instance.storeOwners(0, { from: admin })
        assert.equal(store_owner_before, false, "Store owner should not be added yet.")
        assert.equal(store_owner_after, true, "Store owner should now be added.")
        assert.equal(storeOwners, storeOwner, "Store owner not matched")
    })

    it('Store owner should be able to add a store', async () => {
        await instance.addAdmin(admin, { from: owner })
        await instance.addStoreOwner(storeOwner, { from: admin })
        await instance.addStore(storeId, storeName, { from: storeOwner })
        const stores = await instance.stores(0, { from: storeOwner })
        assert.equal(stores, storeId, "Store not matched")
    })

    it('Customer owner should be able to add a product', async () => {
        await instance.addAdmin(admin, { from: owner })
        await instance.addStoreOwner(storeOwner, { from: admin })
        await instance.addStore(storeId, storeName, { from: storeOwner })
        await instance.addProduct(storeId,productId,productName,quantity,value, { from: storeOwner })
        const products = await instance.product(productId, { from: storeOwner })
        assert.equal(products.name, productName, "Product not matched")
    })

    it('Customer should be able to buy a product', async () => {
        await instance.addAdmin(admin, { from: owner })
        await instance.addStoreOwner(storeOwner, { from: admin })
        await instance.addStore(storeId, storeName, { from: storeOwner })
        await instance.addProduct(storeId,productId,productName,quantity,value, { from: storeOwner })
        await instance.buyProduct(productId,buyQuantity, { from: customer, value: 1 })
        const products = await instance.product(productId, { from: storeOwner })
        assert.equal(products.quantity, quantity-1, "Quantity should get reduced by one")
    })

})