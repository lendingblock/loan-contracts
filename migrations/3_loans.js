var LoanFactory = artifacts.require("./LoanFactory.sol");

const LENDERS_COUNT = 20;
const INTERESTS_COUNT = 12;

const loanByteInput = [
  '31536000',
  '5000000000',
  '700000000000000000000',
  '1528188800',
  '650000000000000000000',
  '750000000000000000000',
  '1528188800'
];
const loanIntInput = [
  '0x8f36c426df8f9a808e37a77e4e1e60601fa2c64a97bc31e8072c8945c00eb49d',
  '0x674bdd49be293c9d3bfa46d1836c31b66b7bab28c271ded795a20e2bbc290b23',
  '0x37401b5b342ce644adffa7805ec5aed5510cb290489ff3582d57867f670d12f3',
  '0x7bb540a8208433bafd9e33b6cec4efc8fb482502bef5fe48542f3f6045e7e6af',
  '0xa709fd3aa96d9faf770e44a5aef2f4808a6fe3a5ddf546568f36ad3a3873f31d',
  '0xaad60a3265e1c3c0dff4ef3474d6c608ca5f7ec61bd7dcbc5a992ad057630691',
  '0x425443',
  '0x455448',
];

let interestPaymentTimes = [];
let interestAmounts = [];
for (let i = 0; i < INTERESTS_COUNT; i++) {
    interestPaymentTimes.push(
        web3.toBigNumber('1528188800')
        .add(web3.toBigNumber(i).times('86400').times('30'))
        .toNumber()
    );
    interestAmounts.push(
      web3.toBigNumber('10000000000000000000000')
      .toNumber()
    );
}

let lenderByteInput = [];
let lenderIntInput = [];
for (let i = 0; i < LENDERS_COUNT; i++) {
    //id
    lenderByteInput.push(web3.sha3(i.toString()));
    //orderId
    lenderByteInput.push(web3.sha3((i * 33).toString()));
    //lenderUserId
    lenderByteInput.push(web3.sha3((i * 77).toString()));
    //amount
    lenderIntInput.push(web3.toBigNumber('700000000000000000000').dividedBy(50).toString());
    //amount weight
    lenderIntInput.push(web3.toBigNumber('500').toString());
    //rate weight
    lenderIntInput.push(web3.toBigNumber('10000').dividedBy(50).toString());
}

module.exports = function(deployer) {
  deployer.deploy(LoanFactory)
  .then((loanFactory) => {
    return loanFactory.newLoan(
      loanByteInput,
      loanIntInput,
      interestPaymentTimes,
      interestAmounts,
      lenderByteInput,
      lenderIntInput
    );
  })
  .then((tx) => {
    console.log('Loan created: ');
    console.log(tx);
  })
  .catch((error) => {
    console.log(error);
  });
};
