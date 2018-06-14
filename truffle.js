module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      currency: 'USD',
      gasPrice: 11
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
