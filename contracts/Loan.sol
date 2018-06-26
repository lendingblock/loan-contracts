pragma solidity 0.4.24;

import "./LoanFactory.sol";

contract Loan {
    LoanFactory public loanFactory;
    bytes32 public id;

    /*
     * Event names follow the pattern `resource`-`action`.
     */

    event TransferExpected(
        bytes32 from,
        bytes32 to,
        uint256 amount,
        bytes32 currency,
        string reason,
        uint256 timestamp
    );

    event TransferObserved(
        bytes32 from,
        bytes32 to,
        uint256 amount,
        bytes32 currency,
        string reason,
        uint256 timestamp
    );

    event InterestChanged(
        uint256 interestId,
        uint256 paymentTime,
        uint256 amount,
        bool paid,
        uint256 timestamp
    );

    event StatusChanged(
        string status,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == loanFactory.owner());
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == loanFactory.worker());
        _;
    }

    constructor(bytes32 _id) public {
        loanFactory = LoanFactory(msg.sender);
        id = _id;
    }

    /*
     * @dev We expect a transfer on Ethereum or another blockchain
     */
    function expectTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string reason, uint256 timestamp)
        external
        onlyWorker
    {
        emit TransferExpected(
            from,
            to,
            amount,
            currency,
            reason,
            timestamp
        );
    }

    /*
     * @dev We witnessed a transfer on Ethereum or another blockchain
     */
    function observeTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string reason, uint256 timestamp)
        external
        onlyWorker
    {
        emit TransferObserved(
            from,
            to,
            amount,
            currency,
            reason,
            timestamp
        );
    }

    function changeStatus(string status, uint256 timestamp)
        external
        onlyWorker
    {
        emit StatusChanged(
            status,
            timestamp
        );
    }

    function changeInterest(uint256 paymentTime, uint256 amount, bool paid, uint256 interestId, uint256 timestamp)
        external
        onlyOwner
    {
        emit InterestChanged(
            interestId,
            paymentTime,
            amount,
            paid,
            timestamp
        );
    }

    function() external {
        revert();
    }

}
