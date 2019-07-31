## Avoiding Common Attacks
The Marketplace Dapp avoids and keeps in check the following attacks:

## Re-entracy Attacks
In case of recursively entry on a function from an external call, (in case of withdrawBalance/withdrawAuctionUserBid), all the internal work is done before making the external call.

## Denial of Service
While sending ethers, it could be the case that instead of a externally owned account, a contract's fallack function is called,
always reverting the function, thus denying its access.
This is avoided by using Withdrawal Pattern.

## Transaction Ordering and Timestamp Dependence
Since miners can choose the order of transactions from the mempool to include into a block,
they can to some extent contrrol the timestamp of any transaction.
So, while in the Auction smart contract, block.number is used instead of block.timestamp,
which is much difficult to manipulate by the miners.