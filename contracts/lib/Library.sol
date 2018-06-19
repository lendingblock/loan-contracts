pragma solidity 0.4.24;

library Library {
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

    struct DataUint {
        uint256 varUint01;
        uint256 varUint02;
        uint256 varUint03;
        uint256 varUint04;
        uint256 varUint05;
        uint256 varUint06;
        uint256 varUint07;
        uint256 varUint08;
        uint256 varUint09;
        uint256 varUint10;
    }

    struct DataBytes {
        bytes32 varBytes01;
        bytes32 varBytes02;
        bytes32 varBytes03;
        bytes32 varBytes04;
        bytes32 varBytes05;
        bytes32 varBytes06;
        bytes32 varBytes07;
        bytes32 varBytes08;
        bytes32 varBytes09;
        bytes32 varBytes10;
    }

    event ExpectedTransfer(bytes32 id, bytes32 orderId, uint256 amount, bytes32 lenderUserId, uint256 rate, string functionName);

    function store10Uint(DataUint storage self, uint256[10] value)
        public
    {
        self.varUint01 = value[0];
        self.varUint02 = value[1];
        self.varUint03 = value[2];
        self.varUint04 = value[3];
        self.varUint05 = value[4];
        self.varUint06 = value[5];
        self.varUint07 = value[6];
        self.varUint08 = value[7];
        self.varUint09 = value[8];
        self.varUint10 = value[9];
    }

    function store10Bytes(DataBytes storage self, bytes32[10] value)
        public
    {
        self.varBytes01 = value[0];
        self.varBytes02 = value[1];
        self.varBytes03 = value[2];
        self.varBytes04 = value[3];
        self.varBytes05 = value[4];
        self.varBytes06 = value[5];
        self.varBytes07 = value[6];
        self.varBytes08 = value[7];
        self.varBytes09 = value[8];
        self.varBytes10 = value[9];
    }

    function store10Struct(Lender[] storage self, uint256[40] inputUint, bytes32[30] inputBytes)
        public
    {
        for (uint256 i = 0; i < inputUint.length / 4; i++) {
            self.push(Lender({
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

    function change10Enum(LoanStatus[1] storage self)
        public
    {
        self[0] = LoanStatus.Pending01;
        self[0] = LoanStatus.Pending02;
        self[0] = LoanStatus.Pending03;
        self[0] = LoanStatus.Pending04;
        self[0] = LoanStatus.Pending05;
        self[0] = LoanStatus.Pending06;
        self[0] = LoanStatus.Pending07;
        self[0] = LoanStatus.Pending08;
        self[0] = LoanStatus.Pending09;
        self[0] = LoanStatus.Pending10;
    }

    function emitEvents(Lender[] storage self)
        public
    {
        for (uint256 i = 0; i < self.length; i++) {
            emit ExpectedTransfer(
                self[i].id,
                self[i].orderId,
                self[i].amount,
                self[i].lenderUserId,
                self[i].rate,
                "emitEvents"
            );
        }
    }
}
