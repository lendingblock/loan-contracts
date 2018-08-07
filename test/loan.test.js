const uuidv4 = require('uuid/v4');
const LoanFactory = artifacts.require('LoanFactory');
const Loan = artifacts.require('Loan');
const { assertEventContain, assertEventFired, loanGenerator } = require('./utils.js');
let loanFactory;
let loan;

contract('Loan', accounts => {
  it('should create loan', async () => {
    loanFactory = await LoanFactory.deployed();
    let loanExample = loanGenerator();
    const tx = await loanFactory.createLoan(...loanExample.formatToContractArgs());
    const loanAddress = tx.logs[0].args.loanAddress;
    loan = Loan.at(loanAddress);
    const id = await loan.id.call();
    assert.strictEqual(id, loanExample.config.id);
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
    const holdingUserId = uuidv4();
    const loanExample = loanGenerator();
    const tx = await loan.expectTransfer(loanExample.config.parties[0].org_id, holdingUserId, loanExample.config.collateral_amount, loanExample.config.collateral, 'initiation', timestamp, {
      from: accounts[1]
    });
    assertEventFired(tx, 'TransferExpected');
    assertEventContain(tx, { fieldName: 'from', fieldType: 'string' }, loanExample.config.parties[0].org_id);
    assertEventContain(tx, { fieldName: 'to', fieldType: 'string' }, holdingUserId);
    assertEventContain(tx, { fieldName: 'amount', fieldType: 'uint' }, loanExample.config.collateral_amount);
    assertEventContain(tx, { fieldName: 'currency', fieldType: 'bytes32' }, loanExample.config.collateral);
    assertEventContain(tx, { fieldName: 'reason', fieldType: 'string' }, 'initiation');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
    assertEventContain(tx, { fieldName: 'seq', fieldType: 'uint' }, '1');
  });
  it('should not emit TransferExpected event without access', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    try {
      await loan.expectTransfer(loanExample.config.parties[0].org_id, uuidv4(), loanExample.config.collateral_amount, loanExample.config.collateral, 'initiation', timestamp);
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit TransferObserved events when observeTransfer() called', async () => {
    const timestamp = new Date().getTime();
    const holdingUserId = uuidv4();
    const loanExample = loanGenerator();
    const tx = await loan.observeTransfer(
      loanExample.config.parties[0].org_id,
      holdingUserId,
      loanExample.config.collateral_amount,
      loanExample.config.collateral,
      'initiation',
      '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b',
      timestamp,
      { from: accounts[1] }
    );
    assertEventFired(tx, 'TransferObserved');
    assertEventContain(tx, { fieldName: 'from', fieldType: 'string' }, loanExample.config.parties[0].org_id);
    assertEventContain(tx, { fieldName: 'to', fieldType: 'string' }, holdingUserId);
    assertEventContain(tx, { fieldName: 'amount', fieldType: 'uint' }, loanExample.config.collateral_amount);
    assertEventContain(tx, { fieldName: 'currency', fieldType: 'bytes32' }, loanExample.config.collateral);
    assertEventContain(tx, { fieldName: 'reason', fieldType: 'string' }, 'initiation');
    assertEventContain(tx, { fieldName: 'txid', fieldType: 'string' }, '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
    assertEventContain(tx, { fieldName: 'seq', fieldType: 'uint' }, '2');
  });
  it('should not emit TransferObserved event without access', async () => {
    const timestamp = new Date().getTime();
    const loanExample = loanGenerator();
    try {
      await loan.observeTransfer(
        loanExample.config.parties[0].org_id,
        uuidv4(),
        loanExample.config.collateral_amount,
        loanExample.config.collateral,
        'initiation',
        '0x4111de2867be5b56730eeb3047ca4ff4638481c9bc33bed0476c8b72beb97b2b',
        timestamp
      );
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit MetaUpdated events when updateMeta() called', async () => {
    const timestamp = new Date().getTime();
    const meta = {
      status: 'ACTIVE',
      timestamp: timestamp
    };
    const tx = await loan.updateMeta(JSON.stringify(meta), { from: accounts[1] });
    assertEventFired(tx, 'MetaUpdated');
    assertEventContain(tx, { fieldName: 'updatedMeta', fieldType: 'string' }, JSON.stringify(meta));
    assertEventContain(tx, { fieldName: 'seq', fieldType: 'uint' }, '3');
  });
  it('should not emit StatusChanged event without access', async () => {
    const timestamp = new Date().getTime();
    try {
      const meta = {
        status: 'ACTIVE',
        timestamp: timestamp
      };
      await loan.updateMeta(JSON.stringify(meta));
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
