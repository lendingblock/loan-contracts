//truffle objects
const LoanFactory = artifacts.require('LoanFactory');
const Loan = artifacts.require('Loan');
const Web3Latest = require('web3'); //We use new version of web3 for its utils module
const web3Latest = new Web3Latest();
const assertEvent = require('./utils.js').assertEvent;

//Fixtures params
const LENDERS_COUNT = 20;
const INTERESTS_COUNT = 12;

//loan main terms
const borrowerUserId = 'borrowerUserId';
const principalCurrency = 'BTC';
const collateralCurrency = 'ETH';
const tenor = '365'; // in days
const market = `${principalCurrency}/${collateralCurrency}-${tenor}`;
const principalAmount = Math.pow(10, 8); //10^8 satoshis = 1 BTC
const collateralAmount = 12 * Math.pow(10, 18); //10^18 = 1 ether

/*
 * Interests
 */
const interests = [];
for (let i = 0; i < INTERESTS_COUNT; i++) {
  const paymentTime = web3.toBigNumber('1528188800')
    .add(web3.toBigNumber(i).times('86400').times('30'))
    .toNumber();
  const interestAmounts = web3.toBigNumber('10000000000000000000000')
    .toNumber();
  const interest = {
    paymentTime,
    interestAmounts
  };
  interests.push(interest);
};

/*
 * Lenders
 */
const lenders = [];
for (let i = 0; i < LENDERS_COUNT; i++) {
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

const loanMeta = {
  createdTime: new Date(),
  lowerRequiredMargin: 0.8,
  higherRequiredMargin: 1.2,
  lastMarginTime: null,
  holdingUserId: 'holdingUserId',
  escrowUserId: 'escrowUserId',
  liquidatorUserId: 'liquidatorUserId',
  lenders,
  interests
};

contract('Loan', (accounts) => {
  it('should create NewLoan event with parameters of loan created', async () => {
    const loanFactory = await LoanFactory.deployed();
    const loanMetaJSON = JSON.stringify(loanMeta);
    const tx = await loanFactory.createLoan(
      borrowerUserId,
      market,
      principalAmount,
      collateralAmount,
      loanMetaJSON
    );
    console.log(`Gas Used: ${tx.receipt.gasUsed}`);
    assertEvent(tx, {fieldName: 'borrowerUserId'}, borrowerUserId);
    assertEvent(tx, {fieldName: 'market'}, market);
    assertEvent(tx, {fieldName: 'principalAmount', fieldType: 'uint'}, principalAmount);
    assertEvent(tx, {fieldName: 'collateralAmount', fieldType: 'uint'}, collateralAmount);
    assertEvent(tx, {fieldName: 'loanMeta', fieldType: 'string'}, loanMetaJSON);
  });

});
