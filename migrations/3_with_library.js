var WithLibrary = artifacts.require("./WithLibrary.sol");
var Library = artifacts.require("./lib/Library.sol");

module.exports = function(deployer) {
  deployer.deploy(Library);
  deployer.link(Library, WithLibrary);
  deployer.deploy(WithLibrary);
};
