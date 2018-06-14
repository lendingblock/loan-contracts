pragma solidity 0.4.24;

import "./LoanFactory.sol";

contract Loan {
    enum LoanStatus {
        Pending,
        Active,
        InterestPayment,
        Liquidated,
        Matured,
        Completed
    }

    struct Lender {
        bytes32 id;
        bytes32 orderId;
        bytes32 lenderUserId;
        uint256 amount;
        uint256 rate;
        uint256 amountWeight;
        uint256 rateWeight;
    }

    struct Interest {
        uint256 paymentTime;
        uint256 amount;
        bool paid;
    }

    LoanFactory public loanFactory;
    uint256 public tenor;
    uint256 public principalAmount;
    uint256 public collateralAmount;
    uint256 public createdTime;
    uint256 public lowerRequiredMargin;
    uint256 public higherRequiredMargin;
    uint256 public lastMarginTime;
    uint256 public constant WEIGHT_DIVISOR = 10000;
    bytes32 public constant INTEREST_CURRENCY = 0x4c4e44;
    bytes32 public borrowerUserId;
    bytes32 public holdingUserId;
    bytes32 public escrowUserId;
    bytes32 public liquidatorUserId;
    bytes32 public id;
    bytes32 public orderId;
    bytes32 public principalCurrency;
    bytes32 public collateralCurrency;
    LoanStatus public status;
    Lender[] public lenders;
    Interest[] public interest;
    uint256 public totalExpectedTransfers;
    bytes32[] public transferOutcomeRecords;
    bytes32 public constant TRANSFER_NOT_SENT = 0x4e4f545f53454e54;

    event ExpectedTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, uint256 totalExpectedTransfers, string functionName);

    modifier onlyLoanFactory() {
        require(msg.sender == address(loanFactory));
        _;
    }

    constructor(
        uint256[7] newLoanUintInput,
        bytes32[8] newLoanBytesInput
    )
        public
    {
        loanFactory = LoanFactory(msg.sender);
        tenor = newLoanUintInput[0];
        principalAmount = newLoanUintInput[1];
        collateralAmount = newLoanUintInput[2];
        createdTime = newLoanUintInput[3];
        lowerRequiredMargin = newLoanUintInput[4];
        higherRequiredMargin = newLoanUintInput[5];
        lastMarginTime = newLoanUintInput[6];
        borrowerUserId = newLoanBytesInput[0];
        holdingUserId = newLoanBytesInput[1];
        escrowUserId = newLoanBytesInput[2];
        liquidatorUserId = newLoanBytesInput[3];
        id = newLoanBytesInput[4];
        orderId = newLoanBytesInput[5];
        principalCurrency = newLoanBytesInput[6];
        collateralCurrency = newLoanBytesInput[7];
    }

    function() external {
        revert();
    }

    function changeInterest(uint256 paymentTime, uint256 amount, bool paid, uint256 interestId)
        external
        onlyLoanFactory
    {
        interest[interestId].paymentTime = paymentTime;
        interest[interestId].amount = amount;
        interest[interestId].paid = paid;
    }

    function changeStatus(LoanStatus _status)
        external
        onlyLoanFactory
    {
        status = _status;
    }

    function changeInterestPaid(uint256 interestId)
        external
        onlyLoanFactory
    {
        require(interest[interestId].paid == false);
        interest[interestId].paid = true;
    }

    function changeCollateralAmount(uint256 _collateralAmount)
        external
        onlyLoanFactory
    {
        collateralAmount = _collateralAmount;
    }

    function changeMargin(uint256 _lowerRequiredMargin, uint256 _higherRequiredMargin, uint256 _lastMarginTime)
        external
        onlyLoanFactory
    {
        lowerRequiredMargin = _lowerRequiredMargin;
        higherRequiredMargin = _higherRequiredMargin;
        lastMarginTime = _lastMarginTime;
    }

    function changeTransferOutcomeRecords(bytes32 _transferOutcomeRecords, uint256 transferOutcomeRecordsId)
        external
        onlyLoanFactory
    {
        transferOutcomeRecords[transferOutcomeRecordsId] = _transferOutcomeRecords;
    }

    function addLenders(
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        external
        onlyLoanFactory
    {
        require(status == LoanStatus.Pending);
        for (uint256 i = 0; i < lenderUintInput.length / 4; i++) {
            lenders.push(Lender({
                id: lenderBytesInput[3 * i + 0],
                orderId: lenderBytesInput[3 * i + 1],
                lenderUserId: lenderBytesInput[3 * i + 2],
                amount: lenderUintInput[4 * i + 0],
                rate: lenderUintInput[4 * i + 1],
                amountWeight: lenderUintInput[4 * i + 2],
                rateWeight: lenderUintInput[4 * i + 3]
            }));
        }
    }

    function addInterest(
        uint256[] paymentTime,
        uint256[] amount
    )
        external
        onlyLoanFactory
    {
        require(status == LoanStatus.Pending);
        for (uint256 i = 0; i < paymentTime.length; i++) {
            interest.push(Interest({
                paymentTime: paymentTime[i],
                amount: amount[i],
                paid: false
            }));
        }
    }

    function emitExpectedTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string functionName)
        external
        onlyLoanFactory
    {
        emit ExpectedTransfer(from, to, amount, currency, totalExpectedTransfers++, functionName);
    }

    function addTransferOutcomeRecords(bytes32[] _transferOutcomeRecords)
        external
        onlyLoanFactory
    {
        for (uint256 i = 0; i < _transferOutcomeRecords.length; i++) {
            transferOutcomeRecords.push(_transferOutcomeRecords[i]);
        }
        require(transferOutcomeRecords.length <= totalExpectedTransfers);
    }

    function isOutcomeRecordsUpdated()
        public
        view
        returns (bool)
    {
        if (transferOutcomeRecords.length == totalExpectedTransfers) {
            return true;
        } else {
            return false;
        }
    }

    function isLastOutcomeRecordSent()
        public
        view
        returns (bool)
    {
        if (transferOutcomeRecords[totalExpectedTransfers - 1] != TRANSFER_NOT_SENT) {
            return true;
        } else {
            return false;
        }
    }

    function lendersLength()
        public
        view
        returns (uint256)
    {
        return lenders.length;
    }

    function lendersMember(uint256 lendersId)
        public
        view
        returns (bytes32, uint256, uint256)
    {
        return (lenders[lendersId].lenderUserId, lenders[lendersId].amountWeight, lenders[lendersId].rateWeight);
    }

    function interestMember(uint256 interestId)
        public
        view
        returns (uint256, uint256, bool)
    {
        return (interest[interestId].paymentTime, interest[interestId].amount, interest[interestId].paid);
    }
}
