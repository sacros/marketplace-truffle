# Design Pattern Decisions
The Marketplace Dapp implements the following design patterns:

## Fail early and fail loud
Using modifiers for the check conditions allows the smart contract function not to be called if required conditions are not met.
This reduces unnecessary code execution in the event that an exception will be thrown.
In the Marketplace smart contract, modifiers are used for checking various attributes such as:
- user access (onlyAdmin/onlyStoreOwner/etc)
- validity of input (validBid/productExists/etc),and
- logics (sufficientFunds/sufficientBalance)

## Restricting Access
For restrict access to functions, modifiers that validate user type are used.
Also, some functions (removeProductFromStore/removeAdminFromAdminList/etc) are made internal,
limiting their access to functions inside this contract, which alongside modifiers are used to make the smart contract more secure.

## Mortal
The Marketplace smart contract implements Mortal design pattern to include the ability to destroy the contract.
In such case, all the funds will be transfered to the contract owner.

## Pull over Push Payments/ Withdrawal Pattern
For protection against re-entrancy and denial of service attacks, the Withdrawal pattern has been implemented
in the Marketplace smart contract.
In the case where store owners are to be paid for the bought items, instead of transferring individual funds
to the store owner, the contract adds it to its own balance, and increases the balance(to be transferred to store owner)
in a state variable, to which store owner can withdraw anytime.
Same withdrawal pattern is also implemented in the case of customers placing bid for auctionable products.

## Circuit Breaker
In order to prevent from any attacks, the Marketplace contract follows the circuit breaker patter, which enables the ability
to pause the smart contract's function's execution.
This ability is given to the contract's owner.
Using modifiers like whenNotPaused/whenPaused adds the ability to control access based on the pause status.
