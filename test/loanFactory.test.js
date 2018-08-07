const truffleEvent = require('truffle-events');
const LoanFactory = artifacts.require('LoanFactory');
const { assertEventContain, assertEventFired, loanGenerator } = require('./utils.js');
let loanFactory;

contract('LoanFactory', accounts => {
  it('should store correct owner', async () => {
    loanFactory = await LoanFactory.deployed();
    const owner = await loanFactory.owner.call();
    assert.strictEqual(owner, accounts[0]);
  });
  it('should store correct worker', async () => {
    const worker = await loanFactory.worker.call();
    assert.strictEqual(worker, accounts[0]);
  });
  it('should change pendingOwner', async () => {
    const tx = await loanFactory.changeOwner(accounts[3]);
    const pendingOwner = await loanFactory.pendingOwner.call();
    assert.strictEqual(pendingOwner, accounts[3]);
    assertEventFired(tx, 'AccessChanged');
    assertEventContain(tx, { fieldName: 'access', fieldType: 'string' }, 'pendingOwner');
    assertEventContain(tx, { fieldName: 'previous', fieldType: 'address' }, '0x0000000000000000000000000000000000000000');
    assertEventContain(tx, { fieldName: 'current', fieldType: 'address' }, accounts[3]);
  });
  it('should change pendingOwner again', async () => {
    const tx = await loanFactory.changeOwner(accounts[1]);
    const pendingOwner = await loanFactory.pendingOwner.call();
    assert.strictEqual(pendingOwner, accounts[1]);
    assertEventFired(tx, 'AccessChanged');
    assertEventContain(tx, { fieldName: 'access', fieldType: 'string' }, 'pendingOwner');
    assertEventContain(tx, { fieldName: 'previous', fieldType: 'address' }, accounts[3]);
    assertEventContain(tx, { fieldName: 'current', fieldType: 'address' }, accounts[1]);
  });
  it('should not change pendingOwner without access', async () => {
    try {
      await loanFactory.changeOwner(accounts[1], { from: accounts[1] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should not change owner without access', async () => {
    try {
      await loanFactory.acceptOwner({ from: accounts[0] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should change owner', async () => {
    const tx = await loanFactory.acceptOwner({ from: accounts[1] });
    const pendingOwner = await loanFactory.pendingOwner.call();
    assert.strictEqual(pendingOwner, '0x0000000000000000000000000000000000000000');
    const owner = await loanFactory.owner.call();
    assert.strictEqual(owner, accounts[1]);
    assertEventFired(tx, 'AccessChanged');
    assertEventContain(tx, { fieldName: 'access', fieldType: 'string' }, 'owner');
    assertEventContain(tx, { fieldName: 'previous', fieldType: 'address' }, accounts[0]);
    assertEventContain(tx, { fieldName: 'current', fieldType: 'address' }, accounts[1]);
    assertEventFired(tx, 'AccessChanged');
    assertEventContain(tx, { logIndex: 1, fieldName: 'access', fieldType: 'string' }, 'pendingOwner');
    assertEventContain(tx, { logIndex: 1, fieldName: 'previous', fieldType: 'address' }, accounts[1]);
    assertEventContain(tx, { logIndex: 1, fieldName: 'current', fieldType: 'address' }, '0x0000000000000000000000000000000000000000');
  });
  it('should change worker', async () => {
    const tx = await loanFactory.changeWorker(accounts[2], { from: accounts[1] });
    const worker = await loanFactory.worker.call();
    assert.strictEqual(worker, accounts[2]);
    assertEventFired(tx, 'AccessChanged');
    assertEventContain(tx, { fieldName: 'access', fieldType: 'string' }, 'worker');
    assertEventContain(tx, { fieldName: 'previous', fieldType: 'address' }, accounts[0]);
    assertEventContain(tx, { fieldName: 'current', fieldType: 'address' }, accounts[2]);
  });
  it('should not change worker without access', async () => {
    try {
      await loanFactory.changeWorker(accounts[0], { from: accounts[2] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should change back worker', async () => {
    await loanFactory.changeWorker(accounts[0], { from: accounts[1] });
    const worker = await loanFactory.worker.call();
    assert.strictEqual(worker, accounts[0]);
  });
  it('should emit LoanCreated, MetaUpdated event when createLoan() is called', async () => {
    const loanExample = loanGenerator();
    const tx = await loanFactory.createLoan(...loanExample.formatToContractArgs());
    const loanAddress = await loanFactory.loans(0);
    assertEventFired(tx, 'LoanCreated');
    assertEventContain(tx, { fieldName: 'loanAddress', fieldType: 'address' }, loanAddress);
    assertEventContain(tx, { fieldName: 'id', fieldType: 'string' }, loanExample.config.id);
    assertEventContain(tx, { fieldName: 'seq', fieldType: 'uint' }, '1');
    let metaUpdated = truffleEvent.formTxObject('Loan', 0, tx);
    assert.strictEqual(metaUpdated.logs[0].args.updatedMeta, loanExample.metaString);
    assert.strictEqual(metaUpdated.logs[0].args.seq, '0');
  });
  it('should increment seq when createLoan() is called again', async () => {
    const loanExample = loanGenerator();
    const tx = await loanFactory.createLoan(...loanExample.formatToContractArgs());
    const loanAddress = await loanFactory.loans(1);
    assertEventFired(tx, 'LoanCreated');
    assertEventContain(tx, { fieldName: 'loanAddress', fieldType: 'address' }, loanAddress);
    assertEventContain(tx, { fieldName: 'id', fieldType: 'string' }, loanExample.config.id);
    assertEventContain(tx, { fieldName: 'seq', fieldType: 'uint' }, '2');
  });
  it('should not emit LoanCreated, MetaUpdated event without access', async () => {
    const loanExample = loanGenerator();
    try {
      await loanFactory.createLoan(...loanExample.formatToContractArgs(), { from: accounts[1] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should emit LeadTimeChanged event when changeLeadtime() is called', async () => {
    const timestamp = new Date().getTime();
    const tx = await loanFactory.changeLeadtime('margin', '14400', timestamp, { from: accounts[0] });
    assertEventFired(tx, 'LeadTimeChanged');
    assertEventContain(tx, { fieldName: 'leadTimeType', fieldType: 'bytes32' }, 'margin');
    assertEventContain(tx, { fieldName: 'leadTime', fieldType: 'uint' }, '14400');
    assertEventContain(tx, { fieldName: 'timestamp', fieldType: 'uint' }, timestamp);
  });
  it('should not emit LeadTimeChanged event without access', async () => {
    const timestamp = new Date().getTime();
    try {
      await loanFactory.changeLeadtime('margin', '14400', timestamp, { from: accounts[1] });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should not accept unspecified functions', async () => {
    try {
      await loanFactory.sendTransaction({ from: accounts[1], data: '0x7ef71f11' });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
  it('should not accept eth', async () => {
    try {
      await loanFactory.sendTransaction({ from: accounts[1], value: '10' });
      assert.fail('this tx should fail');
    } catch (e) {
      assert.strictEqual(e.message, 'VM Exception while processing transaction: revert');
    }
  });
});
