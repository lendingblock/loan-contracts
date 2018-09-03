pragma solidity 0.4.24;

import "./LoanFactory.sol";

contract Loan {
    LoanFactory public loanFactory;
    string public id;
    uint256 public seq;

    /*
     * Event names follow the pattern `resource`-`action`.
     */

    event TransferExpected(
        string from,
        string to,
        uint256 amount,
        bytes32 currency,
        string reason,
        uint256 timestamp,
        uint256 seq
    );

    event TransferObserved(
        string from,
        string to,
        uint256 amount,
        bytes32 currency,
        string reason,
        bytes32 txid,
        uint256 timestamp,
        uint256 seq
    );

    event MetaUpdated(
        string updatedMeta,
        uint256 seq
    );

    modifier onlyWorker() {
        require(msg.sender == loanFactory.worker());
        _;
    }

    constructor(string _id, string loanMeta) public {
        loanFactory = LoanFactory(msg.sender);
        id = _id;
        emit MetaUpdated(loanMeta, seq++);
    }

    /*
     * @dev We expect a transfer on Ethereum or another blockchain
     */
    function expectTransfer(
        string from,
        string to,
        uint256 amount,
        bytes32 currency,
        string reason,
        uint256 timestamp
    )
        external
        onlyWorker
    {
        emit TransferExpected(
            from,
            to,
            amount,
            currency,
            reason,
            timestamp,
            seq++
        );
    }

    /*
     * @dev We witnessed a transfer on Ethereum or another blockchain
     */
    function observeTransfer(
        string from,
        string to,
        uint256 amount,
        bytes32 currency,
        string reason,
        bytes32 txid,
        uint256 timestamp
    )
        external
        onlyWorker
    {
        emit TransferObserved(
            from,
            to,
            amount,
            currency,
            reason,
            txid,
            timestamp,
            seq++
        );
    }

    function updateMeta(
        string updatedMeta
    )
        external
        onlyWorker
    {
        emit MetaUpdated(updatedMeta, seq++);
    }

    function() external {
        revert();
    }

}
