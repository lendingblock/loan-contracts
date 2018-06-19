pragma solidity 0.4.24;

contract NoLibrary {
    address public owner;
    address public worker;
    address[] public children;
    uint256 public childId;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        worker = msg.sender;
        children.length = 1;
    }

    function() external {
        revert();
    }

    function newChild()
        external
        onlyOwner
    {
        NoLibraryChild child = new NoLibraryChild();
        children.push(child);
        childId++;
    }
}

contract NoLibraryChild {
    enum LoanStatus {
        Pending01,
        Pending02,
        Pending03,
        Pending04,
        Pending05,
        Pending06,
        Pending07,
        Pending08,
        Pending09,
        Pending10
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

    NoLibrary public factory;
    uint256 public varUint01;
    uint256 public varUint02;
    uint256 public varUint03;
    uint256 public varUint04;
    uint256 public varUint05;
    uint256 public varUint06;
    uint256 public varUint07;
    uint256 public varUint08;
    uint256 public varUint09;
    uint256 public varUint10;
    bytes32 public varBytes01;
    bytes32 public varBytes02;
    bytes32 public varBytes03;
    bytes32 public varBytes04;
    bytes32 public varBytes05;
    bytes32 public varBytes06;
    bytes32 public varBytes07;
    bytes32 public varBytes08;
    bytes32 public varBytes09;
    bytes32 public varBytes10;
    Lender[] public lenders;
    LoanStatus public status;

    event ExpectedTransfer(bytes32 id, bytes32 orderId, uint256 amount, bytes32 lenderUserId, uint256 rate, string functionName);

    modifier onlyWorker() {
        require(msg.sender == factory.worker());
        _;
    }

    constructor()
        public
    {
        factory = NoLibrary(msg.sender);
    }

    function() external {
        revert();
    }

    function store10Uint(uint256[10] input)
        external
        onlyWorker
    {
        varUint01 = input[0];
        varUint02 = input[1];
        varUint03 = input[2];
        varUint04 = input[3];
        varUint05 = input[4];
        varUint06 = input[5];
        varUint07 = input[6];
        varUint08 = input[7];
        varUint09 = input[8];
        varUint10 = input[9];
    }

    function store10Bytes(bytes32[10] input)
        external
        onlyWorker
    {
        varBytes01 = input[0];
        varBytes02 = input[1];
        varBytes03 = input[2];
        varBytes04 = input[3];
        varBytes05 = input[4];
        varBytes06 = input[5];
        varBytes07 = input[6];
        varBytes08 = input[7];
        varBytes09 = input[8];
        varBytes10 = input[9];
    }

    function store10Struct(uint256[40] inputUint, bytes32[30] inputBytes)
        external
        onlyWorker
    {
        for (uint256 i = 0; i < inputUint.length / 4; i++) {
            lenders.push(Lender({
                id: inputBytes[3 * i],
                orderId: inputBytes[3 * i + 1],
                lenderUserId: inputBytes[3 * i + 2],
                amount: inputUint[4 * i],
                rate: inputUint[4 * i + 1],
                amountWeight: inputUint[4 * i + 2],
                rateWeight: inputUint[4 * i + 3]
            }));
        }
    }

    function change10Enum()
        external
        onlyWorker
    {
        status = LoanStatus.Pending01;
        status = LoanStatus.Pending02;
        status = LoanStatus.Pending03;
        status = LoanStatus.Pending04;
        status = LoanStatus.Pending05;
        status = LoanStatus.Pending06;
        status = LoanStatus.Pending07;
        status = LoanStatus.Pending08;
        status = LoanStatus.Pending09;
        status = LoanStatus.Pending10;
    }

    function emitEvents()
        external
        onlyWorker
    {
        for (uint256 i = 0; i < lenders.length; i++) {
            emit ExpectedTransfer(
                lenders[i].id,
                lenders[i].orderId,
                lenders[i].amount,
                lenders[i].lenderUserId,
                lenders[i].rate,
                "emitEvents"
            );
        }
    }
}
