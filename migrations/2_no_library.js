var NoLibrary = artifacts.require("./NoLibrary.sol");

module.exports = function(deployer) {
  deployer.deploy(NoLibrary);
};
