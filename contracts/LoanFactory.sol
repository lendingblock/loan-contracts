pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract Loan is Ownable {
    enum LoanStatus {
        Pending,
        Active,
        InterestPaymentInDefault,
        MarginCall,
        MarginCallInDefault,
        PrincipalRepaymentDefault,
        Liquidated,
        Matured,
        Completed
    }

    struct Lender {
        bytes32 id;
        bytes32 orderId;
        bytes32 lenderUserId;
        uint256 amount;
        uint256 price;
        uint256 weight;
    }

    struct Interest {
        uint256 paymentTime;
        uint256 amount;
        bool paid;
    }

    address public worker;
    uint256 public tenor;
    uint256 public principalAmount;
    uint256 public collateralAmount;
    uint256 public createdTime;
    uint256 public lowerRequiredMargin;
    uint256 public higherRequiredMargin;
    uint256 public lastMarginTime;
    uint256 public marginLeadTime;
    uint256 public matureLeadTime;
    uint256 public interestLeadTime;
    uint256 public constant INTEREST_DIVISOR = 10000;
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
    uint256 public transferRecordsId;
    bytes32[] public transferRecords;
    bytes32 public constant DEFAULT_TRANSFER_RECORD = 0xdeadbeef;

    event Transfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, uint256 transferRecordsId, string functionName);

    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }

    constructor(
        uint256[10] newLoanUintInput,
        bytes32[8] newLoanBytesInput,
        address _owner,
        address _worker
    )
        public
    {
        tenor = newLoanUintInput[0];
        principalAmount = newLoanUintInput[1];
        collateralAmount = newLoanUintInput[2];
        createdTime = newLoanUintInput[3];
        lowerRequiredMargin = newLoanUintInput[4];
        higherRequiredMargin = newLoanUintInput[5];
        marginLeadTime = newLoanUintInput[6];
        lastMarginTime = newLoanUintInput[7];
        matureLeadTime = newLoanUintInput[8];
        interestLeadTime = newLoanUintInput[9];
        borrowerUserId = newLoanBytesInput[0];
        holdingUserId = newLoanBytesInput[1];
        escrowUserId = newLoanBytesInput[2];
        liquidatorUserId = newLoanBytesInput[3];
        id = newLoanBytesInput[4];
        orderId = newLoanBytesInput[5];
        principalCurrency = newLoanBytesInput[6];
        collateralCurrency = newLoanBytesInput[7];
        owner = _owner;
        worker = _worker;
    }

    function() external {
        revert();
    }

    function changeWorker(address _worker)
        external
        onlyOwner
    {
        worker = _worker;
    }

    function changeMarginLeadTime(uint256 _marginLeadTime)
        external
        onlyOwner
    {
        marginLeadTime = _marginLeadTime;
    }

    function changeMatureLeadTime(uint256 _matureLeadTime)
        external
        onlyOwner
    {
        matureLeadTime = _matureLeadTime;
    }

    function changeInterest(uint256 paymentTime, uint256 amount, bool paid, uint256 interestId)
        external
        onlyOwner
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


    function addLenders(
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        external
        onlyWorker
    {
        require(status == LoanStatus.Pending);
        for (uint256 i = 0; i < lenderUintInput.length / 3; i++) {
            lenders.push(Lender({
                id: lenderBytesInput[3 * i + 0],
                orderId: lenderBytesInput[3 * i + 1],
                lenderUserId: lenderBytesInput[3 * i + 2],
                amount: lenderUintInput[3 * i + 0],
                price: lenderUintInput[3 * i + 1],
                weight: lenderUintInput[3 * i + 2]
            }));
        }
    }

    function addInterest(
        uint256[] paymentTime,
        uint256[] amount,
        bool[] paid
    )
        external
        onlyWorker
    {
        require(status == LoanStatus.Pending);
        for (uint256 i = 0; i < paymentTime.length; i++) {
            interest.push(Interest({
                paymentTime: paymentTime[i],
                amount: amount[i],
                paid: paid[i]
            }));
        }
    }

    function start()
        external
        onlyWorker
    {
        require(status == LoanStatus.Pending);
        status = LoanStatus.Active;
        emit Transfer(holdingUserId, borrowerUserId, principalAmount, principalCurrency, transferRecordsId++, "start");
        emit Transfer(holdingUserId, escrowUserId, collateralAmount, collateralCurrency, transferRecordsId++, "start");
    }

    function addTransferRecords(bytes32[] _transferRecords)
        external
        onlyWorker
    {
        for (uint256 i = 0; i < _transferRecords.length; i++) {
            transferRecords.push(_transferRecords[i]);
        }
        require(transferRecords.length <= transferRecordsId);
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
        for (uint256 i = 0; i < lenders.length; i++) {
            emit Transfer(
                borrowerUserId,
                lenders[i].lenderUserId,
                interest[interestId].amount * lenders[i].weight / INTEREST_DIVISOR,
                INTEREST_CURRENCY,
                transferRecordsId++,
                "payInterest"
            );
        }
    }

    function interestDefault(uint256 interestId, uint256 liquidateCollateralAmount)
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        require(interest[interestId].paid == false);
        require(now > interest[interestId].paymentTime + interestLeadTime);
        require(transferRecords[transferRecordsId - 1] == DEFAULT_TRANSFER_RECORD);
        emit Transfer(
            escrowUserId,
            liquidatorUserId,
            liquidateCollateralAmount,
            collateralCurrency,
            transferRecordsId++,
            "interestDefault"
        );
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
        require(now > lastMarginTime + marginLeadTime);
        status = LoanStatus.MarginCallInDefault;
        emit Transfer(
            escrowUserId,
            liquidatorUserId,
            collateralAmount,
            collateralCurrency,
            transferRecordsId++,
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
        uint256 releaseAmount = collateralAmount - (lowerRequiredMargin + higherRequiredMargin) / 2;
        emit Transfer(
            escrowUserId,
            borrowerUserId,
            releaseAmount,
            collateralCurrency,
            transferRecordsId++,
            "marginExcess"
        );
        collateralAmount -= releaseAmount;
    }

    function mature()
        external
        onlyWorker
    {
        require(status == LoanStatus.Active);
        require(now >= createdTime + tenor);
        require(transferRecords.length == transferRecordsId);
        status = LoanStatus.Matured;
        emit Transfer(
            borrowerUserId,
            escrowUserId,
            principalAmount,
            principalCurrency,
            transferRecordsId++,
            "mature"
        );
    }

    function matureDefault()
        external
        onlyWorker
    {
        require(status == LoanStatus.Matured);
        require(now >= createdTime + tenor + matureLeadTime);
        require(transferRecords[transferRecordsId - 1] == DEFAULT_TRANSFER_RECORD);
        status = LoanStatus.PrincipalRepaymentDefault;
        emit Transfer(
            escrowUserId,
            liquidatorUserId,
            collateralAmount,
            collateralCurrency,
            transferRecordsId++,
            "matureDefault"
        );
    }

    function complete()
        external
        onlyWorker
    {
        require(transferRecords.length == transferRecordsId);
        require(transferRecords[transferRecordsId - 1] != DEFAULT_TRANSFER_RECORD);
        if (status == LoanStatus.Matured) {
            status = LoanStatus.Completed;
        } else if (status == LoanStatus.PrincipalRepaymentDefault) {
            status = LoanStatus.Completed;
        } else {
            revert();
        }
    }
}


contract LoanFactory is Ownable {
    address public worker;
    address[] public loans;
    uint256 public loanId;

    event NewLoan(address indexed loan, uint256 loanId);

    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }

    constructor() public {
        worker = msg.sender;
        loans.length = 1;
    }

    function() external {
        revert();
    }

    function changeWorker(address _worker)
        external
        onlyOwner
    {
        worker = _worker;
    }

    function newLoan(
        uint256[10] newLoanUintInput,
        bytes32[8] newLoanBytesInput
    )
        external
        onlyOwner
    {
        Loan loan = new Loan(newLoanUintInput, newLoanBytesInput, owner, worker);
        loans.push(loan);
        loanId++;
        emit NewLoan(loan, loanId);
    }
}
