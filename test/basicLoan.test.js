let LoanFactory = artifacts.require("LoanFactory");
let Loan = artifacts.require("Loan");
let instance;
let loan;
let status;
let lendersCount = 5;
let interestCount = 1;

contract('LoanFactory', (accounts) => {
  it('owner', async() => {
    instance = await LoanFactory.deployed();
    let owner = await instance.owner.call();
    assert.strictEqual(owner, accounts[0]);
  });
  it('worker', async() => {
    let worker = await instance.worker.call();
    assert.strictEqual(worker, accounts[0]);
  });
  it('newLoan', async() => {
    let newLoan = await instance.newLoan(
      [
        '31536000',
        '5000000000',
        '700000000000000000000',
        '152818880',
        '650000000000000000000',
        '750000000000000000000',
        '1528188800'
      ], [
        '0x8f36c426df8f9a808e37a77e4e1e60601fa2c64a97bc31e8072c8945c00eb49d',
        '0x674bdd49be293c9d3bfa46d1836c31b66b7bab28c271ded795a20e2bbc290b23',
        '0x37401b5b342ce644adffa7805ec5aed5510cb290489ff3582d57867f670d12f3',
        '0x7bb540a8208433bafd9e33b6cec4efc8fb482502bef5fe48542f3f6045e7e6af',
        '0xa709fd3aa96d9faf770e44a5aef2f4808a6fe3a5ddf546568f36ad3a3873f31d',
        '0xaad60a3265e1c3c0dff4ef3474d6c608ca5f7ec61bd7dcbc5a992ad057630691',
        '0x425443',
        '0x455448',
      ]);
    loan = Loan.at(await instance.loans(1));
    status = await loan.status.call();
    assert.strictEqual(status.toString(), '0');
    let lenders1 = [];
    let lenders2 = [];
    for (let i = 0; i < lendersCount; i++) {
      lenders1.push(web3.toBigNumber('700000000000000000000').dividedToIntegerBy(lendersCount).toString());
      lenders1.push(web3.toBigNumber('500').toString());
      lenders1.push(web3.toBigNumber('10000').dividedToIntegerBy(lendersCount).toString());
      lenders1.push(web3.toBigNumber('10000').dividedToIntegerBy(lendersCount).toString());
      lenders2.push(web3.sha3(i.toString()));
      lenders2.push(web3.sha3((i * 33).toString()));
      lenders2.push(web3.sha3((i * 77).toString()));
    }
    let addLenders = await loan.addLenders(lenders1, lenders2);
    let interest1 = [];
    let interest2 = [];
    for (let i = 0; i < interestCount; i++) {
      interest1.push(
        web3.toBigNumber('152818880')
        .add(web3.toBigNumber(i).times('86400').times('30'))
        .toString()
      );
      interest2.push(web3.toBigNumber('10000000000000000000000').toString());
    }
    let addInterest = await loan.addInterest(interest1, interest2);
    let start = await loan.start();
    status = await loan.status.call();
    assert.strictEqual(status.toString(), '1');
  });
  it('addTransferOutcomeRecords', async() => {
    let records = [];
    for (let i = 0; i < 2; i++) {
      records.push(web3.sha3(i.toString()));
    }
    let addTransferOutcomeRecords = await loan.addTransferOutcomeRecords(records);
  });
  it('payInterest', async() => {
    let payInterest = await loan.payInterest(0);
    let status = await loan.status.call();
    assert.strictEqual(status.toString(), '2');
  });
  it('addTransferOutcomeRecords', async() => {
    let records = [];
    for (let i = 0; i < lendersCount; i++) {
      records.push(web3.sha3(i.toString()));
    }
    let addTransferOutcomeRecords = await loan.addTransferOutcomeRecords(records);
  });
  it('interestPaid', async() => {
    let interestPaid = await loan.interestPaid(0);
    let status = await loan.status.call();
    assert.strictEqual(status.toString(), '1');
  });
  it('mature', async() => {
    let mature = await loan.mature();
    let status = await loan.status.call();
    assert.strictEqual(status.toString(), '4');
  });
});
