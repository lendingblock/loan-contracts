const LoanFactory = artifacts.require('LoanFactory');
const Loan = artifacts.require('Loan');
const { loanGenerator, toBytes32 } = require('./utils.js');
let loanFactory;
let loan;

contract('lenders10interests0', () => {
  it('should create loan with 10 lenders and 0 interests', async () => {
    const timestamp = new Date().getTime();
    loanFactory = await LoanFactory.deployed();
    loan = loanGenerator({ id: 'id2', lendersCount: 10, interestsCount: 0 });
    const tx = await loanFactory.createLoan(...loan.formatToContractArgs(), timestamp);
    assert.strictEqual(JSON.parse(tx.logs[0].args.loanMeta).lenders.length, 10);
    assert.strictEqual(JSON.parse(tx.logs[0].args.loanMeta).interests.length, 0);
    const loanAddress = tx.logs[0].args.contractAddress;
    loan = Loan.at(loanAddress);
    const id = await loan.id.call();
    assert.strictEqual(id, toBytes32('id2'));
  });
});
