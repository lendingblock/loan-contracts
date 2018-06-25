pragma solidity 0.4.24;

import "./Loan.sol";

contract LoanFactory {
    address public owner;
    address public worker;
    address[] public loans;
    uint256 public loanId;

    /*
     * Event names follow the pattern `resource`-`action`.
     */
    event LoanCreated(
        address contractAddress,
        bytes32 borrowerUserId,
        bytes32 market,
        uint256 principalAmount,
        uint256 collateralAmount,
        string loanMeta
    );

    /*
     * Grace period after a payment instruction, in seconds
     */
    event LeadTimeChanged {
      bytes32 market,
      bytes32 leadTimeType, //can be for margin, interest or principal repayment
      uint256 leadTime,
    };

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

    /*
     * @dev Create new loansome variables were commented out
     * because we hit the stack size limit of the EVM
     * We might have to compress several array element into one
     * to solve the issue
     */
    function createLoan(
        bytes32 borrowerUserId,
        bytes32 market,
        uint256 principalAmount,
        uint256 collateralAmount,
        string loanMeta
    )
        external
        onlyOwner
    {
        Loan loan = new Loan(loanId++);
        loans.push(loan);
        emit LoanCreated(
            loan, //loan address
            borrowerUserId,
            market,
            principalAmount,
            collateralAmount,
            loanMeta
        );
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

    function changeLeadtime(bytes32 market, bytes32 leadTimeType, uint256 leadTime)
        external
        onlyOwner
    {
        emit LeadTimeChanged(
            market,
            leadTimeType,
            leadTime
        );
    }

    function() external {
        revert();
    }
}
