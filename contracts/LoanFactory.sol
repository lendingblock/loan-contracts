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
    constructor () public {
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

    address public worker;

    enum loan_status {
        PENDING,
        ACTIVE,
        INTEREST_PAYMENT_IN_DEFAULT,
        MARGIN_CALL,
        MARGIN_CALL_DEFAULT,
        PRINCIPAL_REPAYMENT_DEFAULT,
        LIQUIDATED,
        MATURED,
        COMPLETED
    }

    struct loanlets_struct {
        bytes32 id;
        bytes32 order_id;
        bytes32 lender_user_id;
        uint256 amount;
        uint256 price;
        uint256 weight;
        loan_status status;
    }

    struct interest_struct {
        uint256 payment_time;
        uint256 amount;
        bool paid;
    }

    uint256 public tenor;
    uint256 public principal_amount;
    uint256 public collateral_amount;
    uint256 public created_time;
    uint256 public lower_required_margin;
    uint256 public higher_required_margin;
    uint256 public last_margin_time;
    uint256 public margin_lead_time;
    uint256 public mature_lead_time;
    uint256 public interest_lead_time;
    uint256 public constant interest_divisor = 10000;
    bytes32 public constant interest_currency = 0x4c4e44;
    bytes32 public borrower_user_id;
    bytes32 public holding_user_id;
    bytes32 public escrow_user_id;
    bytes32 public liquidator_user_id;
    bytes32 public id;
    bytes32 public order_id;
    bytes32 public principal_currency;
    bytes32 public collateral_currency;

    loan_status public status;
    loanlets_struct[] public loanlets;
    interest_struct[] public interest;
    uint256 public transfer_records_id;
    bytes32[] public transfer_records;
    bytes32 public constant default_transfer_record = 0xdeadbeef;

    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }

    event Transfer(bytes32 from, bytes32 to, uint256 amount, bytes32 currency, uint256 transfer_records_id, string function_name);

    function change_worker(address _worker)
        external
        onlyOwner
    {
        worker = _worker;
    }

    function change_margin_lead_time(uint256 _margin_lead_time)
        external
        onlyOwner
    {
        margin_lead_time = _margin_lead_time;
    }

    function change_mature_lead_time(uint256 _mature_lead_time)
        external
        onlyOwner
    {
        mature_lead_time = _mature_lead_time;
    }

    function change_interest(uint256 _payment_time, uint256 _amount, bool _paid, uint256 _interest_id)
        external
        onlyOwner
    {
        interest[_interest_id].payment_time = _payment_time;
        interest[_interest_id].amount = _amount;
        interest[_interest_id].paid = _paid;
    }

    function change_status(loan_status _status)
        external
        onlyOwner
    {
        status = _status;
    }


    function add_loanlets(
        uint256[] _uint_input,
        loan_status[] _status,
        bytes32[] _bytes32_input
    )
        external
        onlyWorker
    {
        require(status == loan_status.PENDING);
        for (uint256 i = 0; i < _status.length; i++) {
            loanlets.push(loanlets_struct({
                id: _bytes32_input[3 * i + 0],
                order_id: _bytes32_input[3 * i + 1],
                lender_user_id: _bytes32_input[3 * i + 2],
                amount: _uint_input[3 * i + 0],
                price: _uint_input[3 * i + 1],
                weight: _uint_input[3 * i + 2],
                status: _status[0]
            }));
        }
    }

    function add_interest(
        uint256[] _payment_time,
        uint256[] _amount,
        bool[] _paid
    )
        external
        onlyWorker
    {
        require(status == loan_status.PENDING);
        for (uint256 i = 0; i < _payment_time.length; i++) {
            interest.push(interest_struct({
                payment_time: _payment_time[i],
                amount: _amount[i],
                paid: _paid[i]
            }));
        }
    }

    function start()
        external
        onlyWorker
    {
        require(status == loan_status.PENDING);
        status = loan_status.ACTIVE;
        emit Transfer(holding_user_id, borrower_user_id, principal_amount, principal_currency, transfer_records_id++, "start");
        emit Transfer(holding_user_id, escrow_user_id, collateral_amount, collateral_currency, transfer_records_id++, "start");
    }

    function add_transfer_records(bytes32[] _transfer_records)
        external
        onlyWorker
    {
        for (uint256 i = 0; i < _transfer_records.length; i++) {
            transfer_records.push(_transfer_records[i]);
        }
        require(transfer_records.length <= transfer_records_id);
    }

    function pay_interest(uint256 _interest_id)
        external
        onlyWorker
    {
        require(status == loan_status.ACTIVE);
        if (_interest_id > 0) {
            require(interest[_interest_id - 1].paid == true);
        }
        require(interest[_interest_id].paid == false);
        require(now >= interest[_interest_id].payment_time);
        for (uint256 i = 0; i < loanlets.length; i++) {
            emit Transfer(
                borrower_user_id,
                loanlets[i].lender_user_id,
                interest[_interest_id].amount*loanlets[i].weight/interest_divisor,
                interest_currency,
                transfer_records_id++,
                "pay_interest"
            );
        }
    }

    function interest_default(uint256 _interest_id, uint256 _liquidate_collateral_amount)
        external
        onlyWorker
    {
        require(status == loan_status.ACTIVE);
        require(interest[_interest_id].paid == false);
        require(now > interest[_interest_id].payment_time + interest_lead_time);
        require(transfer_records[transfer_records_id - 1] == default_transfer_record);
        emit Transfer(escrow_user_id, liquidator_user_id, _liquidate_collateral_amount, collateral_currency, transfer_records_id++, "interest_default");
    }

    function margin_default(uint256 _lower_required_margin, uint256 _higher_required_margin, uint256 _last_margin_time)
        external
        onlyWorker
    {
        require(status == loan_status.ACTIVE);
        lower_required_margin = _lower_required_margin;
        higher_required_margin = _higher_required_margin;
        last_margin_time = _last_margin_time;
        require(collateral_amount < lower_required_margin);
        require(now > last_margin_time + margin_lead_time);
        status = loan_status.MARGIN_CALL_DEFAULT;
        emit Transfer(escrow_user_id, liquidator_user_id, collateral_amount, collateral_currency, transfer_records_id++, "margin_default");
    }

    function margin_excess(uint256 _lower_required_margin, uint256 _higher_required_margin, uint256 _last_margin_time)
        external
        onlyWorker
    {
        require(status == loan_status.ACTIVE);
        lower_required_margin = _lower_required_margin;
        higher_required_margin = _higher_required_margin;
        last_margin_time = _last_margin_time;
        require(collateral_amount > _higher_required_margin);
        uint256 release_amount = collateral_amount - (_lower_required_margin + _higher_required_margin) / 2;
        emit Transfer(
            escrow_user_id,
            borrower_user_id,
            release_amount,
            collateral_currency,
            transfer_records_id++,
            "margin_excess"
        );
        collateral_amount -= release_amount;
    }

    function mature()
        external
        onlyWorker
    {
        require(status == loan_status.ACTIVE);
        require(now >= created_time + tenor);
        require(transfer_records.length == transfer_records_id);
        status = loan_status.MATURED;
        emit Transfer(borrower_user_id, escrow_user_id, principal_amount, principal_currency, transfer_records_id++, "mature");
    }

    function mature_default()
        external
        onlyWorker
    {
        require(status == loan_status.MATURED);
        require(now >= created_time + tenor + mature_lead_time);
        require(transfer_records[transfer_records_id - 1] == default_transfer_record);
        status = loan_status.PRINCIPAL_REPAYMENT_DEFAULT;
        emit Transfer(escrow_user_id, liquidator_user_id, collateral_amount, collateral_currency, transfer_records_id++, "mature_default");
    }

    function complete()
        external
        onlyWorker
    {
        require(transfer_records.length == transfer_records_id);
        require(transfer_records[transfer_records_id - 1] != default_transfer_record);
        if (status == loan_status.MATURED) {
            status = loan_status.COMPLETED;
        } else if (status == loan_status.PRINCIPAL_REPAYMENT_DEFAULT) {
            status = loan_status.COMPLETED;
        } else {
            revert();
        }
    }

    constructor (
        uint256[10] _uint_input,
        bytes32[8] _bytes32_input,
        address _owner,
        address _worker
    )
        public
    {
        tenor = _uint_input[0];
        principal_amount = _uint_input[1];
        collateral_amount = _uint_input[2];
        created_time = _uint_input[3];
        lower_required_margin = _uint_input[4];
        higher_required_margin = _uint_input[5];
        margin_lead_time = _uint_input[6];
        last_margin_time = _uint_input[7];
        mature_lead_time = _uint_input[8];
        interest_lead_time = _uint_input[9];
        borrower_user_id = _bytes32_input[0];
        holding_user_id = _bytes32_input[1];
        escrow_user_id = _bytes32_input[2];
        liquidator_user_id = _bytes32_input[3];
        id = _bytes32_input[4];
        order_id = _bytes32_input[5];
        principal_currency = _bytes32_input[6];
        collateral_currency = _bytes32_input[7];
        owner = _owner;
        worker = _worker;
    }

    function () external {
        revert();
    }
}

contract LoanFactory is Ownable {

    address public worker;
    address[] public loans;
    uint256 public loan_id;

    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }

    event New_loan(address indexed loan, uint256 loan_id);

    constructor () public {
        worker = msg.sender;
        loans.length = 1;
    }

    function change_worker(address _worker)
        external
        onlyOwner
    {
        worker = _worker;
    }

    function new_loan(
        uint256[10] _uint_input,
        bytes32[8] _bytes32_input
    )
        external
        onlyOwner
    {
        Loan createdLoan = new Loan(_uint_input, _bytes32_input, owner, worker);
        loans.push(createdLoan);
        loan_id++;
        emit New_loan(createdLoan, loan_id);
    }

    function () external {
        revert();
    }
}
