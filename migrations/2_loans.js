var LoanFactory = artifacts.require('./LoanFactory.sol');

module.exports = async function(deployer) {
  deployer.deploy(LoanFactory);
};
