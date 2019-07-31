const HDWalletProvider = require('truffle-hdwallet-provider');
const infuraKey = "1aa284178f654456836fcd5c171f4150";

const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
    development: {
     host: "127.0.0.1",
     port: 9545,
     network_id: "*",
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/' + infuraKey),
      host: "localhost",
      port: 8545,
      network_id: 4,
      confirmations: 6,
      timeoutBlocks: 200
    }
  },

  compilers: {
    solc: {
      settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
      }
    }
  }
}
