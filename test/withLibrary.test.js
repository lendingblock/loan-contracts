let Factory = artifacts.require('WithLibrary');
let Child = artifacts.require('WithLibraryChild');
let factory;
let child;
let tx;

contract('WithLibrary', (accounts) => {
  it('constructor', async() => {
    factory = await Factory.deployed();
    let owner = await factory.owner.call();
    assert.strictEqual(owner, accounts[0]);
    let worker = await factory.worker.call();
    assert.strictEqual(worker, accounts[0]);
  });
  it('newChild', async() => {
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    tx = await factory.newChild();
    let childId = await factory.childId.call();
    assert.strictEqual(childId.toString(), '10');
    let childAddress = await factory.children(childId);
    child = Child.at(childAddress);
    let factoryAddress = await child.factory.call();
    assert.strictEqual(factoryAddress, factory.address);
  });
  it('store10Uint', async() => {
    let uint10 = [];
    for (let i = 0; i < 10; i++) {
      uint10.push(web3.toBigNumber(i * 2 + 1).times('1e18').toString());
    }
    tx = await child.store10Uint(uint10);
    let varUint = await child.varUint.call();
    assert.strictEqual(varUint[0].toString(), uint10[0]);
    for (let i = 0; i < 10; i++) {
      uint10.push(web3.toBigNumber(i * 30 + 1).times('1e18').toString());
    }
    tx = await child.store10Uint(uint10);
    varUint = await child.varUint.call();
    assert.strictEqual(varUint[0].toString(), uint10[0]);
    for (let i = 0; i < 10; i++) {
      uint10.push(web3.toBigNumber(i * 500 + 1).times('1e18').toString());
    }
    tx = await child.store10Uint(uint10);
    varUint = await child.varUint.call();
    assert.strictEqual(varUint[0].toString(), uint10[0]);
  });
  it('store10Bytes', async() => {
    let bytes10 = [];
    for (let i = 0; i < 10; i++) {
      bytes10.push(web3.sha3(web3.toBigNumber(i * 2 + 1).times('1e18').toString()));
    }
    tx = await child.store10Bytes(bytes10);
    let varBytes = await child.varBytes.call();
    assert.strictEqual(varBytes[0].toString(), bytes10[0]);
    for (let i = 0; i < 10; i++) {
      bytes10.push(web3.sha3(web3.toBigNumber(i * 30 + 1).times('1e18').toString()));
    }
    tx = await child.store10Bytes(bytes10);
    varBytes = await child.varBytes.call();
    assert.strictEqual(varBytes[0].toString(), bytes10[0]);
    for (let i = 0; i < 10; i++) {
      bytes10.push(web3.sha3(web3.toBigNumber(i * 500 + 1).times('1e18').toString()));
    }
    tx = await child.store10Bytes(bytes10);
    varBytes = await child.varBytes.call();
    assert.strictEqual(varBytes[0].toString(), bytes10[0]);
  });
  it('store10Struct', async() => {
    let uint40 = [];
    let bytes30 = [];
    for (let i = 0; i < 40; i++) {
      uint40.push(web3.toBigNumber(i * 3 + 1).times('1e18').toString());
    }
    for (let i = 0; i < 30; i++) {
      bytes30.push(web3.sha3(web3.toBigNumber(i * 3 + 1).times('1e18').toString()));
    }
    tx = await child.store10Struct(uint40, bytes30);
    let varStruct01 = await child.lenders.call(0);
    assert.strictEqual(varStruct01[0].toString(), bytes30[0]);
    assert.strictEqual(varStruct01[3].toString(), uint40[0]);
    for (let i = 0; i < 40; i++) {
      uint40.push(web3.toBigNumber(i * 40 + 1).times('1e18').toString());
    }
    for (let i = 0; i < 30; i++) {
      bytes30.push(web3.sha3(web3.toBigNumber(i * 40 + 1).times('1e18').toString()));
    }
    tx = await child.store10Struct(uint40, bytes30);
    varStruct01 = await child.lenders.call(0);
    assert.strictEqual(varStruct01[0].toString(), bytes30[0]);
    assert.strictEqual(varStruct01[3].toString(), uint40[0]);
    for (let i = 0; i < 40; i++) {
      uint40.push(web3.toBigNumber(i * 600 + 1).times('1e18').toString());
    }
    for (let i = 0; i < 30; i++) {
      bytes30.push(web3.sha3(web3.toBigNumber(i * 600 + 1).times('1e18').toString()));
    }
    tx = await child.store10Struct(uint40, bytes30);
    varStruct01 = await child.lenders.call(0);
    assert.strictEqual(varStruct01[0].toString(), bytes30[0]);
    assert.strictEqual(varStruct01[3].toString(), uint40[0]);
  });
  it('change10Enum', async() => {
    tx = await child.change10Enum();
    let status = await child.status.call(0);
    assert.strictEqual(status.toString(), '9');
    tx = await child.change10Enum();
    status = await child.status.call(0);
    assert.strictEqual(status.toString(), '9');
    tx = await child.change10Enum();
    status = await child.status.call(0);
    assert.strictEqual(status.toString(), '9');
  });
  it('emitEvents', async() => {
    tx = await child.emitEvents();
    assert.strictEqual(tx.receipt.logs.length, 30);
    tx = await child.emitEvents();
    assert.strictEqual(tx.receipt.logs.length, 30);
    tx = await child.emitEvents();
    assert.strictEqual(tx.receipt.logs.length, 30);
  });
});
