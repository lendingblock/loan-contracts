pragma solidity 0.4.24;

import "./Loan.sol";
import "./lib/SafeMath.sol";

contract LoanFactory {
    using SafeMath for uint256;

    address public owner;
    address public worker;
    address[] public loans;
    uint256 public loanId;
    mapping(bytes32 => uint256) public marginLeadTime;
    mapping(bytes32 => uint256) public matureLeadTime;
    mapping(bytes32 => uint256) public interestLeadTime;

    event NewLoan(address indexed loan, uint256 loanId);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }

    constructor() public {
        owner = msg.sender;
        worker = msg.sender;
        loans.length = 1;
    }

    function() external {
        revert();
    }

    function changeOwner(address _owner)
        external
        onlyOwner
    {
        owner = _owner;
    }

    function changeWorker(address _worker)
        external
        onlyOwner
    {
        worker = _worker;
    }

    function changeMarginLeadTime(bytes32 collateralCurrency, uint256 _marginLeadTime)
        external
        onlyOwner
    {
        marginLeadTime[collateralCurrency] = _marginLeadTime;
    }

    function changeMatureLeadTime(bytes32 collateralCurrency, uint256 _matureLeadTime)
        external
        onlyOwner
    {
        matureLeadTime[collateralCurrency] = _matureLeadTime;
    }

    function changeInterestLeadTime(bytes32 collateralCurrency, uint256 _interestLeadTime)
        external
        onlyOwner
    {
        interestLeadTime[collateralCurrency] = _interestLeadTime;
    }

    function newLoan(
        uint256[7] newLoanUintInput,
        bytes32[8] newLoanBytesInput
    )
        external
        onlyOwner
    {
        Loan loan = new Loan(newLoanUintInput, newLoanBytesInput);
        loans.push(loan);
        loanId++;
        emit NewLoan(loan, loanId);
    }

    function changeInterest(Loan loan, uint256 paymentTime, uint256 amount, bool paid, uint256 interestId)
        external
        onlyOwner
    {
        loan.changeInterest(paymentTime, amount, paid, interestId);
    }

    function changeTransferOutcomeRecords(Loan loan, bytes32 transferOutcomeRecords, uint256 transferOutcomeRecordsId)
        external
        onlyOwner
    {
        loan.changeTransferOutcomeRecords(transferOutcomeRecords, transferOutcomeRecordsId);
    }

    function addLenders(
        Loan loan,
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        external
        onlyWorker
    {
        loan.addLenders(lenderUintInput, lenderBytesInput);
    }

    function addInterest(
        Loan loan,
        uint256[] paymentTime,
        uint256[] amount
    )
        external
        onlyWorker
    {
        loan.addInterest(paymentTime, amount);
    }

    function start(Loan loan)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Pending);
        loan.changeStatus(Loan.LoanStatus.Active);
        loan.emitExpectedTransfer(loan.holdingUserId(), loan.borrowerUserId(), loan.principalAmount(), loan.principalCurrency(), "start");
        loan.emitExpectedTransfer(loan.holdingUserId(), loan.escrowUserId(), loan.collateralAmount(), loan.collateralCurrency(), "start");
    }

    function addTransferOutcomeRecords(Loan loan, bytes32[] transferOutcomeRecords)
        external
        onlyWorker
    {
        loan.addTransferOutcomeRecords(transferOutcomeRecords);
    }

    function payInterest(Loan loan, uint256 interestId)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Active);
        uint256 paymentTime;
        uint256 amount;
        bool paid;
        (paymentTime, amount, paid) = loan.interestMember(interestId);
        if (interestId > 0) {
            bool previousPaid;
            (, , previousPaid) = loan.interestMember(interestId - 1);
            require(previousPaid == true);
        }
        require(paid == false);
        require(now >= paymentTime);
        loan.changeStatus(Loan.LoanStatus.InterestPayment);
        for (uint256 i = 0; i < loan.lendersLength(); i++) {
            bytes32 lenderUserId;
            uint256 rateWeight;
            (lenderUserId, , rateWeight) = loan.lendersMember(i);
            uint256 interestToPay = amount.mul(rateWeight).div(loan.WEIGHT_DIVISOR());
            loan.emitExpectedTransfer(
                loan.borrowerUserId(),
                lenderUserId,
                interestToPay,
                loan.INTEREST_CURRENCY(),
                "payInterest"
            );
        }
    }

    function interestPaid(Loan loan, uint256 interestId)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.InterestPayment);
        require(loan.isOutcomeRecordsUpdated() == true);
        require(loan.isLastOutcomeRecordSent() == true);
        loan.changeInterestPaid(interestId);
        loan.changeStatus(Loan.LoanStatus.Active);
    }

    function interestDefault(Loan loan, uint256 interestId, uint256 liquidateCollateralAmount)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.InterestPayment);
        uint256 paymentTime;
        (paymentTime, , ) = loan.interestMember(interestId);
        require(now > paymentTime + interestLeadTime[loan.collateralCurrency()]);
        require(loan.isOutcomeRecordsUpdated() == true);
        require(loan.isLastOutcomeRecordSent() == false);
        loan.changeStatus(Loan.LoanStatus.Active);
        loan.emitExpectedTransfer(
            loan.escrowUserId(),
            loan.liquidatorUserId(),
            liquidateCollateralAmount,
            loan.collateralCurrency(),
            "interestDefault"
        );
        loan.changeCollateralAmount(loan.collateralAmount().sub(liquidateCollateralAmount));
    }

    function marginDefault(Loan loan, uint256 lowerRequiredMargin, uint256 higherRequiredMargin, uint256 lastMarginTime)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Active);
        loan.changeMargin(lowerRequiredMargin, higherRequiredMargin, lastMarginTime);
        require(loan.collateralAmount() < loan.lowerRequiredMargin());
        require(now > lastMarginTime + marginLeadTime[loan.collateralCurrency()]);
        loan.changeStatus(Loan.LoanStatus.Liquidated);
        loan.emitExpectedTransfer(
            loan.escrowUserId(),
            loan.liquidatorUserId(),
            loan.collateralAmount(),
            loan.collateralCurrency(),
            "marginDefault"
        );
    }

    function marginExcess(Loan loan, uint256 lowerRequiredMargin, uint256 higherRequiredMargin, uint256 lastMarginTime)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Active);
        loan.changeMargin(lowerRequiredMargin, higherRequiredMargin, lastMarginTime);
        require(loan.collateralAmount() > loan.higherRequiredMargin());
        uint256 returnAmount = loan.collateralAmount().sub((loan.lowerRequiredMargin().add(loan.higherRequiredMargin())).div(2));
        loan.emitExpectedTransfer(
            loan.escrowUserId(),
            loan.borrowerUserId(),
            returnAmount,
            loan.collateralCurrency(),
            "marginExcess"
        );
        loan.changeCollateralAmount(loan.collateralAmount().sub(returnAmount));
    }

    function addMargin(Loan loan, uint256 lowerRequiredMargin, uint256 higherRequiredMargin, uint256 lastMarginTime, uint256 collateralAdded)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Active);
        loan.changeMargin(lowerRequiredMargin, higherRequiredMargin, lastMarginTime);
        loan.emitExpectedTransfer(
            loan.borrowerUserId(),
            loan.escrowUserId(),
            collateralAdded,
            loan.collateralCurrency(),
            "addMargin"
        );
        loan.changeCollateralAmount(loan.collateralAmount().add(collateralAdded));
    }

    function mature(Loan loan)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Active);
        require(now >= loan.createdTime() + loan.tenor());
        require(loan.isOutcomeRecordsUpdated() == true);
        loan.changeStatus(Loan.LoanStatus.Matured);
        loan.emitExpectedTransfer(
            loan.borrowerUserId(),
            loan.escrowUserId(),
            loan.principalAmount(),
            loan.principalCurrency(),
            "mature"
        );
    }

    function matureDefault(Loan loan)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Matured);
        require(now >= loan.createdTime() + loan.tenor() + matureLeadTime[loan.collateralCurrency()]);
        require(loan.isOutcomeRecordsUpdated() == true);
        require(loan.isLastOutcomeRecordSent() == false);
        loan.changeStatus(Loan.LoanStatus.Liquidated);
        loan.emitExpectedTransfer(
            loan.escrowUserId(),
            loan.liquidatorUserId(),
            loan.collateralAmount(),
            loan.collateralCurrency(),
            "matureDefault"
        );
    }

    function completeLiquidation(Loan loan, uint256 principalRecovered)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Liquidated);
        require(loan.isOutcomeRecordsUpdated() == true);
        require(loan.isLastOutcomeRecordSent() == false);
        loan.changeStatus(Loan.LoanStatus.Completed);
        for (uint256 i = 0; i < loan.lendersLength(); i++) {
            bytes32 lenderUserId;
            uint256 amountWeight;
            (lenderUserId, amountWeight, ) = loan.lendersMember(i);
            uint256 principalToReturn = principalRecovered.mul(amountWeight).div(loan.WEIGHT_DIVISOR());
            loan.emitExpectedTransfer(
                loan.escrowUserId(),
                lenderUserId,
                principalToReturn,
                loan.principalCurrency(),
                "completeLiquidation"
            );
        }
    }

    function completeMature(Loan loan)
        external
        onlyWorker
    {
        require(loan.status() == Loan.LoanStatus.Liquidated);
        require(loan.isOutcomeRecordsUpdated() == true);
        require(loan.isLastOutcomeRecordSent() == false);
        loan.changeStatus(Loan.LoanStatus.Completed);
        loan.emitExpectedTransfer(
            loan.escrowUserId(),
            loan.borrowerUserId(),
            loan.collateralAmount(),
            loan.collateralCurrency(),
            "completeMature"
        );
        for (uint256 i = 0; i < loan.lendersLength(); i++) {
            bytes32 lenderUserId;
            uint256 amountWeight;
            (lenderUserId, amountWeight, ) = loan.lendersMember(i);
            uint256 principalToReturn = loan.principalAmount().mul(amountWeight).div(loan.WEIGHT_DIVISOR());
            loan.emitExpectedTransfer(
                loan.escrowUserId(),
                lenderUserId,
                principalToReturn,
                loan.principalCurrency(),
                "completeMature"
            );
        }
    }
}
