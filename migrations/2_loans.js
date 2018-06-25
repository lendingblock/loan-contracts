var LoanFactory = artifacts.require("./LoanFactory.sol");

module.exports = async function(deployer) {
  try {
    const loanFactory = await deployer.deploy(LoanFactory)
  } catch(e) {
    console.log(`Error during migration of loanFactory: ${e.message}`);
  }
};
