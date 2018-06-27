const LoanFactory = artifacts.require('LoanFactory');
const Loan = artifacts.require('Loan');
const { assertEventContain, assertEventFired, loanGenerator, toBytes32 } = require('./utils.js');
let loanFactory;
let loan;

contract('Loan', accounts => {
  it('should create loan', async () => {
    const timestamp = new Date().getTime();
    loanFactory = await LoanFactory.deployed();
    loan = loanGenerator({ id: 'id2' });
    const tx = await loanFactory.createLoan(...loan.formatToContractArgs(), timestamp);
    const loanAddress = tx.logs[0].args.contractAddress;
    loan = Loan.at(loanAddress);
    const id = await loan.id.call();
    assert.strictEqual(id, toBytes32('id2'));
    const loanFactoryValue = await loan.loanFactory.call();
    assert.strictEqual(loanFactoryValue, loanFactory.address);
  });
  it('should change worker', async () => {
    await loanFactory.changeWorker(accounts[1]);
    const worker = await loanFactory.worker.call();
    assert.strictEqual(worker, accounts[1]);
  });
  it('should emit TransferExpected events when expectTransfer() called', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    const tx = await loan.expectTransfer(
      loanExample.meta.borrowerUserId,
      loanExample.meta.holdingUserId,
      loanExample.meta.collateralAmount,
      loanExample.meta.collateralCurrency,
      'initiation',
      timestamp,
      { from: accounts[1] }
    );
    assertEventFired(tx, 'TransferExpected');
    assertEventContain(tx, { fieldName: 'from', fieldType: 'bytes32' }, loanExample.meta.borrowerUserId);
    assertEventContain(tx, { fieldName: 'to', fieldType: 'bytes32' }, loanExample.meta.holdingUserId);
    assertEventContain(tx, { fieldName: 'amount', fieldType: 'uint' }, loanExample.meta.collateralAmount);
    assertEventContain(tx, { fieldName: 'currency', fieldType: 'bytes32' }, loanExample.meta.collateralCurrency);
    assertEventContain(tx, { fieldName: 'reason', fieldType: 'string' }, 'initiation');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
  });
  it('should not emit TransferExpected event without access', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    try {
      await loan.expectTransfer(loanExample.meta.borrowerUserId, loanExample.meta.holdingUserId, loanExample.meta.collateralAmount, loanExample.meta.collateralCurrency, 'initiation', timestamp);
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit TransferObserved events when observeTransfer() called', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    const tx = await loan.observeTransfer(
      loanExample.meta.borrowerUserId,
      loanExample.meta.holdingUserId,
      loanExample.meta.collateralAmount,
      loanExample.meta.collateralCurrency,
      'initiation',
      '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b',
      timestamp,
      { from: accounts[1] }
    );
    assertEventFired(tx, 'TransferObserved');
    assertEventContain(tx, { fieldName: 'from', fieldType: 'bytes32' }, loanExample.meta.borrowerUserId);
    assertEventContain(tx, { fieldName: 'to', fieldType: 'bytes32' }, loanExample.meta.holdingUserId);
    assertEventContain(tx, { fieldName: 'amount', fieldType: 'uint' }, loanExample.meta.collateralAmount);
    assertEventContain(tx, { fieldName: 'currency', fieldType: 'bytes32' }, loanExample.meta.collateralCurrency);
    assertEventContain(tx, { fieldName: 'reason', fieldType: 'string' }, 'initiation');
    assertEventContain(tx, { fieldName: 'txid', fieldType: 'string' }, '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
  });
  it('should not emit TransferObserved event without access', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    try {
      await loan.observeTransfer(
        loanExample.meta.borrowerUserId,
        loanExample.meta.holdingUserId,
        loanExample.meta.collateralAmount,
        loanExample.meta.collateralCurrency,
        'initiation',
        '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b',
        timestamp
      );
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit StatusChanged events when changeStatus() called', async () => {
    const timestamp = new Date().getTime();
    const tx = await loan.changeStatus('active', timestamp, { from: accounts[1] });
    assertEventFired(tx, 'StatusChanged');
    assertEventContain(tx, { fieldName: 'status', fieldType: 'string' }, 'active');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
  });
  it('should not emit StatusChanged event without access', async () => {
    const timestamp = new Date().getTime();
    try {
      await loan.changeStatus('active', timestamp);
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit InterestChanged events when changeInterest() called', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    const interestId = 3;
    const tx = await loan.changeInterest(interestId, loanExample.meta.interests[interestId].paymentTime, loanExample.meta.interests[interestId].amount, false, timestamp);
    assertEventFired(tx, 'InterestChanged');
    assertEventContain(tx, { fieldName: 'interestId', fieldType: 'uint' }, interestId);
    assertEventContain(tx, { fieldName: 'paymentTime', fieldType: 'uint' }, loanExample.meta.interests[interestId].paymentTime);
    assertEventContain(tx, { fieldName: 'amount', fieldType: 'uint' }, loanExample.meta.interests[interestId].amount);
    assertEventContain(tx, { fieldName: 'paid', fieldType: 'bool' }, false);
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
  });
  it('should not emit InterestChanged event without access', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    const interestId = 3;
    try {
      await loan.changeInterest(interestId, loanExample.meta.interests[interestId].paymentTime, loanExample.meta.interests[interestId].amount, false, timestamp, { from: accounts[1] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should not accept unspecified functions', async () => {
    try {
      await loan.sendTransaction({ from: accounts[1], data: '0x7ef71f11' });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should not accept eth', async () => {
    try {
      await loan.sendTransaction({ from: accounts[1], value: '10' });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
});
