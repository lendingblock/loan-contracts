const LoanFactory = artifacts.require('LoanFactory');
const {assertEventContain, assertEventFired, loanGenerator} = require('./utils.js');

contract('Loan', (accounts) => {
  it('should emit `LoanCreated` event with correct parameters  when `createLoan()` is called', async () => {
    const loanFactory = await LoanFactory.deployed();
    const loan = loanGenerator();
    const tx = await loanFactory.createLoan(...(loan.formatToContractArgs()));

    assertEventFired(tx, 'LoanCreated');
    assertEventContain(tx, {fieldName: 'borrowerUserId'}, loan.borrowerUserId);
    assertEventContain(tx, {fieldName: 'market'}, loan.market);
    assertEventContain(tx, {fieldName: 'principalAmount', fieldType: 'uint'}, loan.principalAmount);
    assertEventContain(tx, {fieldName: 'collateralAmount', fieldType: 'uint'}, loan.collateralAmount);
    assertEventContain(tx, {fieldName: 'loanMeta', fieldType: 'string'}, loan.metaJSON);
  });

});
