pragma solidity 0.4.24;

import "./Loan.sol";

contract LoanFactory {
    address public owner;
    address public newOwner;
    address public worker;
    uint256 public loanCount;

    /*
     * Event names follow the pattern `resource`-`action`.
     */
    event LoanCreated (
        address contractAddress,
        bytes32 id,
        bytes32 market, //Principal/collareral-tenor. ex: BTC/ETH-30D
        uint256 principalAmount,
        uint256 collateralAmount,
        string loanMeta
    );

    /*
     * Grace period after a payment instruction, in seconds
     */
    event LeadTimeChanged (
      bytes32 market,
      bytes32 leadTimeType, //can be for margin, interest or principal repayment
      uint256 leadTime
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
    }

    /*
     * @dev Create new loansome variables were commented out
     * because we hit the stack size limit of the EVM
     * We might have to compress several array element into one
     * to solve the issue
     */
    function createLoan(
        bytes32 loanId,
        bytes32 market,
        uint256 principalAmount,
        uint256 collateralAmount,
        string loanMeta
    )
        external
        onlyWorker
    {
        Loan loan = new Loan(loanId);
        loanCount++;
        emit LoanCreated(
            loan,
            loanId, //loan address
            market,
            principalAmount,
            collateralAmount,
            loanMeta
        );
    }

    function changeOwner(address _newOwner)
        external
        onlyOwner
    {
        newOwner = _newOwner;
    }

    function acceptOwner()
        external
    {
        require(msg.sender == newOwner);
        owner = newOwner;
        newOwner = 0x0;
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
