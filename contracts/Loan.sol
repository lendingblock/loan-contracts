pragma solidity 0.4.24;

import "./LoanFactory.sol";
import "./lib/SafeMath.sol";

contract Loan {
    using SafeMath for uint256;

    enum LoanStatus {
        Pending,
        Active,
        InterestPayment,
        Liquidated,
        Matured,
        Completed
    }

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

    LoanFactory public loanFactory;
    uint256 public id;

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
        LoanStatus status
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

    constructor(uint256 _id) public {
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
        _expectTransfer(from, to, amount, currency, reason);
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

    function changeStatus(LoanStatus status)
        external
        onlyOwner
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

    /*
     * @dev Used internally in constructor to build a lenders array
     * used in `NewLoan` event
     */
    function _addLenders(
        uint256[] lenderUintInput,
        bytes32[] lenderBytesInput
    )
        private
        returns(Lender[])
    {
        Lender[] memory lenders = new Lender[](20);
        for (uint256 i = 0; i < lenderUintInput.length / 4; i++) {
            lenders[i] = Lender({
                id: lenderBytesInput[3 * i + 0],
                orderId: lenderBytesInput[3 * i + 1],
                lenderUserId: lenderBytesInput[3 * i + 2],
                amount: lenderUintInput[4 * i + 0],
                rate: lenderUintInput[4 * i + 1],
                amountWeight: lenderUintInput[4 * i + 2],
                rateWeight: lenderUintInput[4 * i + 3]
            });
        }
        return lenders;
    }

    /*
     * @dev Used internally in constructor to build a interests array
     * used in `NewLoan` event
     */
    function _addInterests(
        uint256[] paymentTimes,
        uint256[] amounts
    )
        private
        returns(Interest[])
    {
        Interest[] memory interests = new Interest[](20);
        for (uint256 i = 0; i < paymentTimes.length; i++) {
            interests[i] = Interest({
                paymentTime: paymentTimes[i],
                amount: amounts[i],
                paid: false
            });
        }
        return interests;
    }

    /*
     * @dev Used internally in constructor
     */
    function _expectTransfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, string reason) 
      internal
    {
        emit TransferExpected(
            from, 
            to, 
            amount, 
            currency, 
            reason
        );
    }

    function() external {
        revert();
    }

}
