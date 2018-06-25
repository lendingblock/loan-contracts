const assert = require('assert');
const Web3Latest = require('web3'); //We use new version of web3 for its utils module
const web3Latest = new Web3Latest();

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
  filter = Object.assign({}, {logIndex: 0, fieldType: 'bytes32'}, filter);
  const result = tx.logs[filter.logIndex].args[filter.fieldName];

  //We need to format the value we are expecting for certain type of string,
  //to match the format returned by the transaction log
  let expected = null;
  if(filter.fieldType === 'bytes32') {
    expected = web3Latest.utils.padRight(web3Latest.utils.fromAscii(value), 64);
  } else if(filter.fieldType === 'uint' || filter.fieldType === 'string') {
    expected = value;
  } else {
    throw new Error('assertEvent: filter.fieldType needs to be `bytes32`');
  }

  assert.equal(result, expected);
}

/**
 * @description Assert an event as fired
 * @param tx - Object: the transaction object
 * @param eventName - String: Name of the event to check
 * @param index - Integer: Index of the event in the transaction logs
 *                         First event to fire is index 0, etc..
 */
const assertEventFired = (tx, eventName, index = 0) => {
  assert.equal(tx.logs[index].event, eventName);
}

class Loan {
  constructor(config = {}) {
    this.config = this.parseConfig(config);

    this.id = this.config.id;
    this.market = this.formatMarket(this.config);
    this.principalAmount = this.config.principalAmount;
    this.collateralAmount = this.config.collateralAmount;

    const interests = this.generateInterests(this.config)
    const lenders = this.generateLenders(this.config)
    this.meta = this.generateMeta(this.config, lenders)
    this.metaJSON = JSON.stringify(this.meta);
  }

  parseConfig(config) {
    return Object.assign({}, {
      id: 'id',
      tenor: 365,
      principalCurrency: 'BTC',
      collateralCurrency: 'ETH',
      lowerRequiredMargin: 0.8,
      higherRequiredMargin: 1.2,
      principalAmount: Math.pow(10, 8), //10^8 satoshis = 1 BTC
      collateralAmount: 12 * Math.pow(10, 18), //10^18 = 1 ether
      lastMarginTime: null,
      borrowerUserId: 'borrowerUserId',
      holdingUserId: 'holdingUserId',
      escrowUserId: 'escrowUserId',
      liquidatorUserId: 'liquidatorUserId',
      lendersCount: 20,
      interestsCount: 12
    }, config);
  }

  generateInterests(config) {
    const interests = [];
    for (let i = 0; i < config.interestsCount; i++) {
      const paymentTime = web3
        .toBigNumber('1528188800')
        .add(web3.toBigNumber(i).times('86400').times('30'))
        .toNumber();
      const interestAmounts = web3
        .toBigNumber('10000000000000000000000')
        .toNumber();
      const interest = {
        paymentTime,
        interestAmounts
      };
      interests.push(interest);
    };
    return interests;
  }

  generateLenders(config) {
    const lenders = [];
    for (let i = 0; i < config.lendersCount; i++) {
      const lender = {
        id: web3.sha3(i.toString()),
        orderId: web3.sha3((i * 33).toString()),
        lenderUserId: web3.sha3((i * 77).toString()),
        amount: web3.toBigNumber('700000000000000000000').dividedBy(50).toString(),
        amountWeight: web3.toBigNumber('500').toString(),
        rateWeight: web3.toBigNumber('10000').dividedBy(50).toString()
      }
      lenders.push(lender);
    }
    return lenders;
  }

  generateMeta(config, lenders, interests) {
    //@todo: filter config to only extract fields that are really meta
    // Currenty everything is passed,resulting in redundant info
    return Object.assign({}, config, {
      lenders,
      interests
    });
  }

  formatMarket(config) {
    return `${config.principalCurrency}/${config.collateralCurrency}-${config.tenor}`;
  }

  formatToContractArgs() {
    return [
      this.id,
      this.market,
      this.principalAmount,
      this.collateralAmount,
      this.metaJSON
    ];
  }

}

const loanGenerator = () => {
  return new Loan();
}

module.exports = {
  assertEventFired,
  assertEventContain,
  loanGenerator
};
