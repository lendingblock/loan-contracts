pragma solidity 0.4.24;

import "./Loan.sol";

contract LoanFactory {
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
        bytes32[8] newLoanBytesInput,
        uint256[] paymentTimes,
        uint256[] amounts,
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        external
        onlyOwner
    {
        Loan loan = new Loan(
          newLoanUintInput, 
          newLoanBytesInput,
          paymentTimes,
          amounts,
          lenderUintInput,
          lenderBytesInput
        );
        loans.push(loan);
        loanId++;
        emit NewLoan(loan, loanId);
    }
}
