const LoanFactory = artifacts.require('LoanFactory');
const Loan = artifacts.require('Loan');
const {assertEventContain, assertEventFired, loanGenerator} = require('./utils.js');

contract('Loan', () => {
  it('should emit `TransferExpected` event with correct parameters when `expectTransfer()` called', async () => {
    //Create a new loan contract
    const timestamp = new Date().getTime();
    const loanFactory = await LoanFactory.deployed();
    const loan = loanGenerator();
    const _tx = await loanFactory.createLoan(...(loan.formatToContractArgs()), timestamp);

    //Call `expectTransfer() on it
    const address = _tx.logs[0].args.contractAddress;
    const tx = await Loan.at(address).expectTransfer(
      loan.meta.borrowerUserId,
      loan.meta.holdingUserId,
      loan.meta.collateralAmount,
      loan.meta.collateralCurrency,
      'initiation',
      timestamp
    );

    assertEventFired(tx, 'TransferExpected');
    assertEventContain(tx, {fieldName: 'from'}, loan.meta.borrowerUserId);
    assertEventContain(tx, {fieldName: 'to'}, loan.meta.holdingUserId);
    assertEventContain(tx, {fieldName: 'amount', fieldType: 'uint'}, loan.meta.collateralAmount);
    assertEventContain(tx, {fieldName: 'currency', fieldType: 'bytes32'}, loan.meta.collateralCurrency);
    assertEventContain(tx, {fieldName: 'reason', fieldType: 'string'}, 'initiation');
    assertEventContain(tx, {fieldName: 'timestamp', fieldType: 'uint'}, timestamp);
  });

});
