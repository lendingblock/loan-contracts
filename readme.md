# Loan smart contracts

[![CircleCI](https://circleci.com/gh/lendingblock/loan-contracts.svg?style=svg)](https://circleci.com/gh/lendingblock/loan-contracts)

[![codecov](https://codecov.io/gh/lendingblock/loan-contracts/branch/master/graph/badge.svg)](https://codecov.io/gh/lendingblock/loan-contracts)

Ethereum smart contracts for creating and managing loans

## Getting started

### To install
```
npm install
```
### To lint and run unit tests with coverage analysis
```
yarn test
```

[Truffle]: http://trufflesuite.com
[Solidity Coverage]: https://github.com/sc-forks/solidity-coverage

### To deploy, there are a few options depending on your setup

#### using truffle and mnemonic

install dependency
```
npm install truffle-hdwallet-provider --save
```
add the following to `truffle.js`
```
let mnemonic = 'your secert words';
let HDWalletProvider = require('truffle-hdwallet-provider');

module.exports = {
  networks: {
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/');
      },
      gasPrice: '10000000000',
      network_id: '*' // Match any network id
    }
  }
};

```
run truffle migrate
```
truffle migrate --network rinkeby
```
#### using truffle and private key

install dependency
```
npm install truffle-privatekey-provider --save
```
add the following to `truffle.js`
```
let privateKey = 'your private key without 0x';
let PrivateKeyProvider = require('truffle-privatekey-provider');

module.exports = {
  networks: {
    rinkeby: {
      provider: () => {
        return new PrivateKeyProvider(privateKey, 'https://rinkeby.infura.io/');
      },
      gasPrice: '10000000000',
      network_id: '*' // Match any network id
    }
  }
};

```
run truffle migrate
```
truffle migrate --network rinkeby
```

#### using mnemonic

install dependency
```
npm install truffle-hdwallet-provider --save
```
run the following javascript script

```
const mnemonic = 'your secert words';
const Web3 = require('web3');
const HDWalletProvider = require('truffle-hdwallet-provider');
const compiledContract = require('./build/contracts/LoanFactory.json');

const provider = new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/');
const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();
  let newContract = new web3.eth.Contract(compiledContract.abi);
  let tx = await newContract
    .deploy({
      data: compiledContract.bytecode
    })
    .send({
      from: accounts[0],
      gas: '6000000',
      gasPrice: '10000000000'
    });
  console.log('Contract deployed to: ', tx.options.address);
};

deploy();
```

#### using private key

install dependency
```
npm install truffle-privatekey-provider --save
```
run the following javascript script

```
const privateKey = 'your private key without 0x';
const Web3 = require('web3');
const PrivateKeyProvider = require('truffle-privatekey-provider');
const compiledContract = require('./build/contracts/LoanFactory.json');

const provider = new PrivateKeyProvider(privateKey, 'https://rinkeby.infura.io/');
const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();
  let newContract = new web3.eth.Contract(compiledContract.abi);
  let tx = await newContract
    .deploy({
      data: compiledContract.bytecode
    })
    .send({
      from: accounts[0],
      gas: '6000000',
      gasPrice: '10000000000'
    });
  console.log('Contract deployed to: ', tx.options.address);
};

deploy();
```
