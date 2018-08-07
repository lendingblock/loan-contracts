const assert = require('assert');
const Web3Latest = require('web3'); //We use new version of web3 for its utils module
const web3Latest = new Web3Latest();
const uuidv4 = require('uuid/v4');

/**
 * @description Assert a transaction log contains an event with a field matching a value
 * @param filter - Object describing the field to assert on and the log of the event:
 *                 {
 *                   fieldName: String,
 *                   fieldType:  ['bytes32', 'uint', 'string'],
 *                   logIndex: Integer
 *                 }
 */
const assertEventContain = (tx, filter, value) => {
  filter = Object.assign(
    {},
    {
      logIndex: 0
    },
    filter
  );
  let result = tx.logs[filter.logIndex].args[filter.fieldName];
  let expected = null;

  //We need to format the value we are expecting for certain type of string,
  //to match the format returned by the transaction log
  if (filter.fieldType === 'bytes32') {
    expected = toBytes32(value);
  } else if (filter.fieldType === 'uint') {
    expected = value.toString();
    result = result.toString();
  } else if (filter.fieldType === 'bool' || filter.fieldType === 'string' || filter.fieldType === 'address') {
    expected = value;
  } else {
    throw new Error('assertEvent: unknown filter.fieldType');
  }

  assert.strictEqual(result, expected);
};

const toBytes32 = value => {
  return web3Latest.utils.padRight(web3Latest.utils.fromAscii(value), 64);
};

/**
 * @description Assert an event as fired
 * @param tx - Object: the transaction object
 * @param eventName - String: Name of the event to check
 * @param index - Integer: Index of the event in the transaction logs
 *                         First event to fire is index 0, etc..
 */
const assertEventFired = (tx, eventName, index = 0) => {
  assert.strictEqual(tx.logs[index].event, eventName);
};

class Loan {
  constructor(config = {}) {
    this.config = this.parseConfig(config);
    const interestCount = config.interestCount ? config.interestCount : 20;
    delete this.config.interestCount;
    const partyCount = config.partyCount ? config.partyCount : 12;
    delete this.config.partyCount;
    if (this.config.interests.length === 0) {
      this.config.interests = this.exampleInterests(interestCount);
    }
    if (this.config.parties.length === 0) {
      this.config.parties = this.exampleParties(partyCount);
    }
    this.metaString = JSON.stringify(this.config);
  }

  parseConfig(config) {
    return Object.assign(
      {},
      {
        id: uuidv4(),
        timestamp: new Date().getTime(),
        status: 'PENDING',
        price: '5.8837',
        tenor: '1m',
        currency: 'BTC',
        collateral: 'ETH',
        principal_amount: web3
          .toBigNumber('10')
          .pow('8')
          .toString(), //10^8 satoshis = 1 BTC
        collateral_amount: web3
          .toBigNumber('10')
          .pow('18')
          .times('12')
          .toString(), //10^18 = 1 ether
        blockchain_address: '',
        factory_blockchain_address: '',
        blockchain: 'ETH',
        legal_contract: '',
        lower_required_margin: web3
          .toBigNumber('10')
          .pow('18')
          .times('12')
          .times('1.1')
          .toString(),
        higher_required_margin: web3
          .toBigNumber('10')
          .pow('18')
          .times('12')
          .times('1.2')
          .toString(),
        liquidator_user_id: uuidv4(),
        last_margin_time: '0',
        created: new Date().getTime(),
        maturity: new Date().getTime() + 60 * 60 * 24 * 30,
        lnd_creation_price: '0.0039',
        principal_creation_price: '7093.8754',
        collateral_creation_price: '412.3875',
        parties: [],
        interests: []
      },
      config
    );
  }

  exampleInterests(count) {
    const interests = [];
    for (let i = 0; i < count; i++) {
      const id = uuidv4();
      const seq = i + 1;
      const payment_time = web3
        .toBigNumber('1528188800')
        .add(
          web3
            .toBigNumber(i)
            .times('86400')
            .times('30')
        )
        .toString();
      const status = 'PENDING';
      const currency = 'LND';
      const amount = web3.toBigNumber('10000000000000000000000').toString();
      const interest = {
        id,
        seq,
        payment_time,
        status,
        currency,
        amount
      };
      interests.push(interest);
    }
    return interests;
  }

  exampleParties(count) {
    const parties = [];
    for (let i = 0; i < count; i++) {
      const party = {
        id: uuidv4(),
        order_id: uuidv4(),
        user_id: uuidv4(),
        org_id: uuidv4(),
        side: 'borrow',
        currency: 'BTC',
        collateral: 'ETH',
        amount: web3
          .toBigNumber('700000000000000000000')
          .dividedBy(parties.length)
          .toString(),
        price: '5.8837',
        timestamp: new Date().getTime(),
        status: 'COMPLETED'
      };
      parties.push(party);
    }
    return parties;
  }

  formatToContractArgs() {
    return [this.config.id, this.metaString];
  }
}

const loanGenerator = config => {
  return new Loan(config);
};

module.exports = {
  assertEventFired,
  assertEventContain,
  loanGenerator,
  toBytes32
};
