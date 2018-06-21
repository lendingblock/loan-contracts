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
const assertEvent = (tx, filter, value) => {
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

module.exports = {
  assertEvent
};
