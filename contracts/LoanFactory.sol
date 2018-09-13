pragma solidity 0.4.24;

import "./Loan.sol";

contract LoanFactory {
    address public owner;
    address public pendingOwner;
    address public worker;
    Loan[] public loans;

    event AccessChanged (
        string access,
        address previous,
        address current
    );

    /*
     * Event names follow the pattern `resource`-`action`.
     */
    event LoanCreated (
        address loanAddress,
        string id,
        uint256 seq
    );

    /*
     * Grace period after a payment instruction, in seconds
     */
    event LeadTimeChanged (
        bytes32 leadTimeType, //can be for margin, interest or principal repayment
        uint256 leadTime,
        uint256 timestamp
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
    function createLoan(string id, string loanMeta)
        public
        onlyWorker
    {
        loans.push(new Loan(id, loanMeta));
        emit LoanCreated(
            loans[loans.length - 1],
            id,
            loans.length
        );
    }

    function changeOwner(address _pendingOwner)
        public
        onlyOwner
    {
        emit AccessChanged("pendingOwner", pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function acceptOwner()
        public
    {
        require(msg.sender == pendingOwner);
        emit AccessChanged("owner", owner, pendingOwner);
        emit AccessChanged("pendingOwner", pendingOwner, 0x0);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }

    function changeWorker(address _worker)
        public
        onlyOwner
    {
        emit AccessChanged("worker", worker, _worker);
        worker = _worker;
    }

    function changeLeadtime(bytes32 leadTimeType, uint256 leadTime, uint256 timestamp)
        public
        onlyWorker
    {
        emit LeadTimeChanged(
            leadTimeType,
            leadTime,
            timestamp
        );
    }

    function() external {
        revert();
    }
}
