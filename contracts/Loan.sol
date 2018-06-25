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
        string reason
    );

    event TransferObserved(
        bytes32 from,
        bytes32 to,
        uint256 amount,
        bytes32 currency,
        string reason
    );

    event InterestChanged(
        uint256 interestId,
        uint256 paymentTime,
        uint256 amount,
        bool paid
    );

    event StatusChanged(
        string status
    );

    modifier onlyOwner() {
        require(msg.sender == loanFactory.owner());
        _;
    }

    modifier onlyWorker() {
        require(msg.sender == loanFactory.worker());
        _;
    }

    function getWorker() public view returns(address, address) {
        return (msg.sender, loanFactory.worker());
    }

    constructor(bytes32 _id) public {
        loanFactory = LoanFactory(msg.sender);
        id = _id;
    }

    /*
     * @dev We expect a transfer on Ethereum or another blockchain
     */
    function expectTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string reason)
        external
        onlyWorker
    {
        emit TransferExpected(
            from,
            to,
            amount,
            currency,
            reason
        );
    }

    /*
     * @dev We witnessed a transfer on Ethereum or another blockchain
     */
    function observeTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string reason)
        external
        onlyWorker
    {
        emit TransferObserved(
            from,
            to,
            amount,
            currency,
            reason
        );
    }

    function changeStatus(string status)
        external
        onlyWorker
    {
        emit StatusChanged(
            status
        );
    }

    function changeInterest(uint256 paymentTime, uint256 amount, bool paid, uint256 interestId)
        external
        onlyOwner
    {
        emit InterestChanged(
            interestId,
            paymentTime,
            amount,
            paid
        );
    }

    function() external {
        revert();
    }

}
