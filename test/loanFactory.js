const LoanFactory = artifacts.require('LoanFactory');
const {assertEvent, loanGenerator} = require('./utils.js');

contract('Loan', (accounts) => {
  it('should create NewLoan event with parameters of loan created', async () => {
    const loanFactory = await LoanFactory.deployed();
    const loan = loanGenerator();
    const tx = await loanFactory.createLoan(...(loan.formatToContractArgs()));
    console.log(`Gas Used: ${tx.receipt.gasUsed}`);
    assertEvent(tx, {fieldName: 'borrowerUserId'}, loan.borrowerUserId);
    assertEvent(tx, {fieldName: 'market'}, loan.market);
    assertEvent(tx, {fieldName: 'principalAmount', fieldType: 'uint'}, loan.principalAmount);
    assertEvent(tx, {fieldName: 'collateralAmount', fieldType: 'uint'}, loan.collateralAmount);
    assertEvent(tx, {fieldName: 'loanMeta', fieldType: 'string'}, loan.metaJSON);
  });

});
