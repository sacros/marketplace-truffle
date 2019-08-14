# Consensys Developer Bootcamp Final Project

## Online Marketplace

#### For the smart contract,
```sh
git clone https://github.com/sacros/marketplace-truffle
```

#### The smart contract can be build/tested/deployed with:
```sh
truffle compile
truffle migrate
```

#### For testing the smart contract:
```sh
truffle develop
truffle test
```

#### For the UI,
```sh
git clone https://github.com/sacros/marketplace-ui
npm i
```
place the `Marketplace.json` file from smart contract's build folder,
`/build/contracts/Marketplace.json` and place in UI's directory: `src/assets/Marketplace.json`
```sh
npm run start
```
