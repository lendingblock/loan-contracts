pragma solidity 0.4.24;

import "./LoanFactory.sol";
import "./lib/SafeMath.sol";

contract Loan {
    using SafeMath for uint256;

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

    modifier onlyOwner() {
        require(msg.sender == loanFactory.owner());
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == loanFactory.worker());
        _;
    }

    constructor(
        uint256[7] newLoanUintInput,
        bytes32[8] newLoanBytesInput,
        uint256[] interestPaymentTimes,
        uint256[] interestAmounts,
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
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

        _addInterest(interestPaymentTimes, interestAmounts);
        _addLenders(lenderUintInput, lenderBytesInput);
        start();
    }

    function() external {
        revert();
    }

    function changeInterest(uint256 paymentTime, uint256 amount, bool paid, uint256 interestId)
        external
        //onlyOwner
    {
        interest[interestId].paymentTime = paymentTime;
        interest[interestId].amount = amount;
        interest[interestId].paid = paid;
    }

    function changeStatus(LoanStatus _status)
        external
        onlyOwner
    {
        status = _status;
    }

    function changeTransferOutcomeRecords(bytes32 _transferOutcomeRecords, uint256 transferOutcomeRecordsId)
        external
        onlyOwner
    {
        transferOutcomeRecords[transferOutcomeRecordsId] = _transferOutcomeRecords;
    }

    function addLenders(
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        external
        onlyWorker
    {
      _addLenders(lenderUintInput, lenderBytesInput);
    }

    function _addLenders(
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        private
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
        onlyWorker
    {
      _addInterest(paymentTime, amount);
    }

    function _addInterest(
        uint256[] paymentTime,
        uint256[] amount
    )
        private
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

    function start()
        private
    {
        require(status == LoanStatus.Pending);
        status = LoanStatus.Active;
        emit ExpectedTransfer(holdingUserId, borrowerUserId, principalAmount, principalCurrency, totalExpectedTransfers++, "start");
        emit ExpectedTransfer(holdingUserId, escrowUserId, collateralAmount, collateralCurrency, totalExpectedTransfers++, "start");
    }

    function addTransferOutcomeRecords(bytes32[] _transferOutcomeRecords)
        external
        onlyWorker
    {
        for (uint256 i = 0; i < _transferOutcomeRecords.length; i++) {
            transferOutcomeRecords.push(_transferOutcomeRecords[i]);
        }
        require(transferOutcomeRecords.length <= totalExpectedTransfers);
    }

    function payInterest(uint256 interestId)
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        if (interestId > 0) {
            require(interest[interestId - 1].paid == true);
        }
        require(interest[interestId].paid == false);
        require(now >= interest[interestId].paymentTime);
        status = LoanStatus.InterestPayment;
        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 interestToPay = interest[interestId].amount.mul(lenders[i].rateWeight).div(WEIGHT_DIVISOR);
            emit ExpectedTransfer(
                borrowerUserId,
                lenders[i].lenderUserId,
                interestToPay,
                INTEREST_CURRENCY,
                totalExpectedTransfers++,
                "payInterest"
            );
        }
    }

    function interestPaid(uint256 interestId)
        external
        onlyWorker
    {
        require(status == LoanStatus.InterestPayment);
        require(isOutcomeRecordsUpdated() == true);
        require(isLastOutcomeRecordSent() == true);
        interest[interestId].paid = true;
        status = LoanStatus.Active;
    }

    function interestDefault(uint256 interestId, uint256 liquidateCollateralAmount)
        external
        onlyWorker
    {
        require(status == LoanStatus.InterestPayment);
        require(now > interest[interestId].paymentTime + loanFactory.interestLeadTime(collateralCurrency));
        require(isOutcomeRecordsUpdated() == true);
        require(isLastOutcomeRecordSent() == false);
        status = LoanStatus.Active;
        emit ExpectedTransfer(
            escrowUserId,
            liquidatorUserId,
            liquidateCollateralAmount,
            collateralCurrency,
            totalExpectedTransfers++,
            "interestDefault"
        );
        collateralAmount = collateralAmount.sub(liquidateCollateralAmount);
    }

    function marginDefault(uint256 _lowerRequiredMargin, uint256 _higherRequiredMargin, uint256 _lastMarginTime)
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        lowerRequiredMargin = _lowerRequiredMargin;
        higherRequiredMargin = _higherRequiredMargin;
        lastMarginTime = _lastMarginTime;
        require(collateralAmount < lowerRequiredMargin);
        require(now > lastMarginTime + loanFactory.marginLeadTime(collateralCurrency));
        status = LoanStatus.Liquidated;
        emit ExpectedTransfer(
            escrowUserId,
            liquidatorUserId,
            collateralAmount,
            collateralCurrency,
            totalExpectedTransfers++,
            "marginDefault"
        );
    }

    function marginExcess(uint256 _lowerRequiredMargin, uint256 _higherRequiredMargin, uint256 _lastMarginTime)
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        lowerRequiredMargin = _lowerRequiredMargin;
        higherRequiredMargin = _higherRequiredMargin;
        lastMarginTime = _lastMarginTime;
        require(collateralAmount > _higherRequiredMargin);
        uint256 returnAmount = collateralAmount.sub((lowerRequiredMargin.add(higherRequiredMargin)).div(2));
        emit ExpectedTransfer(
            escrowUserId,
            borrowerUserId,
            returnAmount,
            collateralCurrency,
            totalExpectedTransfers++,
            "marginExcess"
        );
        collateralAmount = collateralAmount.sub(returnAmount);
    }

    function addMargin(uint256 _lowerRequiredMargin, uint256 _higherRequiredMargin, uint256 _lastMarginTime, uint256 collateralAdded)
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        lowerRequiredMargin = _lowerRequiredMargin;
        higherRequiredMargin = _higherRequiredMargin;
        lastMarginTime = _lastMarginTime;
        emit ExpectedTransfer(
            borrowerUserId,
            escrowUserId,
            collateralAdded,
            collateralCurrency,
            totalExpectedTransfers++,
            "addMargin"
        );
        collateralAmount = collateralAmount.add(collateralAdded);
    }

    function mature()
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        require(now >= createdTime + tenor);
        require(isOutcomeRecordsUpdated() == true);
        status = LoanStatus.Matured;
        emit ExpectedTransfer(
            borrowerUserId,
            escrowUserId,
            principalAmount,
            principalCurrency,
            totalExpectedTransfers++,
            "mature"
        );
    }

    function matureDefault()
        external
        onlyWorker
    {
        require(status == LoanStatus.Matured);
        require(now >= createdTime + tenor + loanFactory.matureLeadTime(collateralCurrency));
        require(isOutcomeRecordsUpdated() == true);
        require(isLastOutcomeRecordSent() == false);
        status = LoanStatus.Liquidated;
        emit ExpectedTransfer(
            escrowUserId,
            liquidatorUserId,
            collateralAmount,
            collateralCurrency,
            totalExpectedTransfers++,
            "matureDefault"
        );
    }

    function completeLiquidation(uint256 principalRecovered)
        external
        onlyWorker
    {
        require(status == LoanStatus.Liquidated);
        require(isOutcomeRecordsUpdated() == true);
        require(isLastOutcomeRecordSent() == true);
        status = LoanStatus.Completed;
        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 principalToReturn = principalRecovered.mul(lenders[i].amountWeight).div(WEIGHT_DIVISOR);
            emit ExpectedTransfer(
                escrowUserId,
                lenders[i].lenderUserId,
                principalToReturn,
                principalCurrency,
                totalExpectedTransfers++,
                "completeLiquidation"
            );
        }
    }

    function completeMature()
        external
        onlyWorker
    {
        require(status == LoanStatus.Matured);
        require(isOutcomeRecordsUpdated() == true);
        require(isLastOutcomeRecordSent() == true);
        status = LoanStatus.Completed;
        emit ExpectedTransfer(
            escrowUserId,
            borrowerUserId,
            collateralAmount,
            collateralCurrency,
            totalExpectedTransfers++,
            "completeMature"
        );
        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 principalToReturn = principalAmount.mul(lenders[i].amountWeight).div(WEIGHT_DIVISOR);
            emit ExpectedTransfer(
                escrowUserId,
                lenders[i].lenderUserId,
                principalToReturn,
                principalCurrency,
                totalExpectedTransfers++,
                "completeMature"
            );
        }
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
}
