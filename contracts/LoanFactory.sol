pragma solidity 0.4.24;

import "./Loan.sol";

contract LoanFactory {
    address public owner;
    address public worker;
    address[] public loans;
    uint256 public loanId;

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

    /*
     * Event names follow the pattern `resource`-`action`.
     */
    event LoanCreated(
      bytes32 borrowerUserId,
      bytes32 market,
      uint256 principalAmount,
      uint256 collateralAmount,
      string loanMeta
    );

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

    function() external {
        revert();
    }
}
