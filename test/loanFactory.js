const LoanFactory = artifacts.require('LoanFactory');
const {assertEventContain, assertEventFired, loanGenerator} = require('./utils.js');

contract('LoanFactory', (accounts) => {
  it('should emit `LoanCreated` event with correct parameters  when `createLoan()` is called', async () => {
    const timestamp = new Date().getTime();
    const loanFactory = await LoanFactory.deployed();
    const loan = loanGenerator();
    const tx = await loanFactory.createLoan(...(loan.formatToContractArgs()), timestamp);

    assertEventFired(tx, 'LoanCreated');
    assertEventContain(tx, {fieldName: 'id'}, loan.id);
    assertEventContain(tx, {fieldName: 'market'}, loan.market);
    assertEventContain(tx, {fieldName: 'principalAmount', fieldType: 'uint'}, loan.principalAmount);
    assertEventContain(tx, {fieldName: 'collateralAmount', fieldType: 'uint'}, loan.collateralAmount);
    assertEventContain(tx, {fieldName: 'loanMeta', fieldType: 'string'}, loan.metaJSON);
    assertEventContain(tx, {fieldName: 'timestamp', fieldType: 'uint'}, timestamp);
  });

});
